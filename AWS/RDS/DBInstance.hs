{-# LANGUAGE FlexibleContexts, RankNTypes, RecordWildCards #-}

module AWS.RDS.DBInstance
    ( describeDBInstances
    , createDBInstance
    , deleteDBInstance
    , createDBInstanceReadReplica
    ) where

import Data.Text (Text)
import Data.Conduit
import Control.Applicative
import Data.XML.Types (Event(..))
import Data.Maybe (catMaybes)

import AWS.Util
import AWS.Lib.Query
import AWS.Lib.Parser

import AWS.RDS.Types hiding (Event)
import AWS.RDS.Internal

describeDBInstances
    :: (MonadBaseControl IO m, MonadResource m)
    => Maybe Text -- ^ DBInstanceIdentifier
    -> Maybe Int -- ^ MaxRecords
    -> Maybe Text -- ^ Marker
    -> RDS m [DBInstance]
describeDBInstances dbid maxRecords marker =
    rdsQuery "DescribeDBInstances" params $
        elements "DBInstance" sinkDBInstance
  where
    params =
        [ "DBInstanceIdentifier" |=? dbid
        , "MaxRecords" |=? toText <$> maxRecords
        , "Marker" |=? marker
        ]

sinkDBInstance
    :: MonadThrow m
    => GLSink Event m DBInstance
sinkDBInstance = DBInstance
    <$> getT "Iops"
    <*> getT "BackupRetentionPeriod"
    <*> getT "DBInstanceStatus"
    <*> getT "MultiAZ"
    <*> elements' "VpcSecurityGroups" "VpcSecurityGroupMembership"
        (VpcSecurityGroupMembership
        <$> getT "Status"
        <*> getT "VpcSecurityGroupId"
        )
    <*> getT "DBInstanceIdentifier"
    <*> getT "PreferredBackupWindow"
    <*> getT "PreferredMaintenanceWindow"
    <*> elementM "OptionGroupMembership"
        (OptionGroupMembership
        <$> getT "OptionGroupName"
        <*> getT "Status"
        )
    <*> getT "AvailabilityZone"
    <*> getT "LatestRestorableTime"
    <*> elements "ReadReplicaDBInstanceIdentifier" text
    <*> getT "Engine"
    <*> sinkPendingModifiedValues
    <*> getT "CharacterSetName"
    <*> getT "LicenseModel"
    <*> elementM "DBSubnetGroup" dbSubnetGroupSink
    <*> elements "DBParameterGroup"
        (DBParameterGroupStatus
        <$> getT "ParameterApplyStatus"
        <*> getT "DBParameterGroupName"
        )
    <*> elementM "Endpoint"
        (Endpoint
        <$> getT "Port"
        <*> getT "Address"
        )
    <*> getT "EngineVersion"
    <*> getT "ReadReplicaSourceDBInstanceIdentifier"
    <*> getT "PubliclyAccessible"
    <*> elements "DBSecurityGroup"
        (DBSecurityGroupMembership
        <$> getT "Status"
        <*> getT "DBSecurityGroupName"
        )
    <*> getT "AutoMinorVersionUpgrade"
    <*> getT "DBName"
    <*> getT "InstanceCreateTime"
    <*> getT "AllocatedStorage"
    <*> getT "DBInstanceClass"
    <*> getT "MasterUsername"

sinkPendingModifiedValues
    :: MonadThrow m
    => GLSink Event m [PendingModifiedValue]
sinkPendingModifiedValues = element "PendingModifiedValues" $
    catMaybes <$> sequence
        [ f PMVMasterUserPassword "MasterUserPassword"
        , f PMVIops "Iops"
        , f PMVMultiAZ "MultiAZ"
        , f PMVAllocatedStorage "AllocatedStorage"
        , f PMVEngineVersion "EngineVersion"
        , f PMVDBInstanceIdentifier "DBInstanceIdentifier"
        , f PMVDBInstanceClass "DBInstanceClass"
        , f PMVBackupRetentionPeriod "BackupRetentionPeriod"
        , f PMVPort "Port"
        ]
  where
    f c name = fmap c <$> getT name

createDBInstance
    :: (MonadBaseControl IO m, MonadResource m)
    => CreateDBInstanceRequest -- ^ data type of CreateDBInstance
    -> RDS m DBInstance
createDBInstance CreateDBInstanceRequest{..} =
    rdsQuery "CreateDBInstance" params $
        element "DBInstance" sinkDBInstance
  where
    params =
        [ "AllocatedStorage" |=
            toText createDBInstanceAllocatedStorage
        , "AutoMinorVersionUpgrade" |=?
            boolToText <$> createDBInstanceAutoMinorVersionUpgrade
        , "AvailabilityZone" |=?
            createDBInstanceAvailabilityZone
        , "BackupRetentionPeriod" |=?
            toText <$> createDBInstanceBackupRetentionPeriod
        , "CharacterSetName" |=?
            createDBInstanceCharacterSetName
        , "DBInstanceClass" |=
            toText createDBInstanceDBInstanceClass
        , "DBInstanceIdentifier" |=
            createDBInstanceDBInstanceIdentifier
        , "DBName" |=? createDBInstanceDBName
        , "DBParameterGroupName" |=?
            createDBInstanceDBParameterGroupName
        , "DBSecurityGroups.member" |.#=
            createDBInstanceDBSecurityGroups
        , "DBSubnetGroupName" |=?
            createDBInstanceDBSubnetGroupName
        , "Engine" |= toText createDBInstanceEngine
        , "EngineVersion" |=? createDBInstanceEngineVersion
        , "Iops" |=? toText <$> createDBInstanceIops
        , "LicenseModel" |=?
            toText <$> createDBInstanceLicenseModel
        , "MasterUserPassword" |= createDBInstanceMasterUserPassword
        , "MasterUsername" |= createDBInstanceMasterUsername
        , "MultiAZ" |=? boolToText <$> createDBInstanceMultiAZ
        , "OptionGroupName" |=? createDBInstanceOptionGroupName
        , "Port" |=? toText <$> createDBInstancePort
        , "PreferredBackupWindow" |=?
            createDBInstancePreferredBackupWindow
        , "PreferredMaintenanceWindow" |=?
            createDBInstancePreferredMaintenanceWindow
        , "PubliclyAccessible" |=?
            boolToText <$> createDBInstancePubliclyAccessible
        , "VpcSecurityGroupIds" |.#=
            createDBInstanceVpcSecurityGroupIds
        ]

deleteDBInstance
    :: (MonadBaseControl IO m, MonadResource m)
    => Text -- ^ DBInstanceIdentifier
    -> FinalSnapshot -- ^ FinalSnapshot
    -> RDS m DBInstance
deleteDBInstance dbiid final =
    rdsQuery "DeleteDBInstance" params $
        element "DBInstance" sinkDBInstance
  where
    params =
        [ "DBInstanceIdentifier" |= dbiid
        ] ++ finalSnapshotParams final
    finalSnapshotParams SkipFinalSnapshot =
        [ "SkipFinalSnapshot" |= boolToText True ]
    finalSnapshotParams (FinalSnapshotIdentifier sid) =
        [ "SkipFinalSnapshot" |= boolToText False
        , "FinalSnapshotIdentifier" |= sid
        ]

createDBInstanceReadReplica
    :: (MonadBaseControl IO m, MonadResource m)
    => CreateReadReplicaRequest
    -> RDS m DBInstance
createDBInstanceReadReplica CreateReadReplicaRequest{..} =
    rdsQuery "CreateDBInstanceReadReplica" params $
        element "DBInstance" sinkDBInstance
  where
    params =
        [ "AutoMinorVersionUpgrade" |=?
            boolToText <$> createReadReplicaAutoMinorVersionUpgrade
        , "AvailabilityZone" |=?
            createReadReplicaAvailabilityZone
        , "DBInstanceClass" |=
            toText createReadReplicaDBInstanceClass
        , "DBInstanceIdentifier" |=
            createReadReplicaDBInstanceIdentifier
        , "Iops" |=? toText <$> createReadReplicaIops
        , "OptionGroupName" |=? createReadReplicaOptionGroupName
        , "Port" |=? toText <$> createReadReplicaPort
        , "PubliclyAccessible" |=?
            boolToText <$> createReadReplicaPubliclyAccessible
        , "SourceDBInstanceIdentifier" |=
            createReadReplicaSourceDBInstanceIdentifier
        ]
