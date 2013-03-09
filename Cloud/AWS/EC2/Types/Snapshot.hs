{-# LANGUAGE TemplateHaskell #-}

module Cloud.AWS.EC2.Types.Snapshot
    ( CreateVolumePermission(..)
    , CreateVolumePermissionItem(..)
    , ResetSnapshotAttributeRequest(..)
    , Snapshot(..)
    , SnapshotAttribute(..)
    , SnapshotAttributeRequest(..)
    , SnapshotStatus(..)
    ) where

import Cloud.AWS.EC2.Types.Common (ProductCode, ResourceTag)
import Cloud.AWS.Lib.FromText
import Cloud.AWS.Lib.ToText

data CreateVolumePermission = CreateVolumePermission
    { createVolumePermissionAdd :: [CreateVolumePermissionItem]
    , createVolumePermissionRemove :: [CreateVolumePermissionItem]
    }
  deriving (Show, Read, Eq)

data CreateVolumePermissionItem
    = CreateVolumePermissionItemUserId Text
    | CreateVolumePermissionItemGroup Text
  deriving (Show, Read, Eq)

data ResetSnapshotAttributeRequest
    = ResetSnapshotAttributeRequestCreateVolumePermission
  deriving (Show, Read, Eq)

instance ToText ResetSnapshotAttributeRequest where
    toText ResetSnapshotAttributeRequestCreateVolumePermission
        = "createVolumePermission"

data Snapshot = Snapshot
    { snapshotId :: Text
    , snapshotVolumeId :: Maybe Text
    , snapshotStatus :: SnapshotStatus
    , snapshotStartTime :: UTCTime
    , snapshotProgress :: Maybe Text
    , snapshotOwnerId :: Text
    , snapshotVolumeSize :: Int
    , snapshotDescription :: Maybe Text
    , snapshotOwnerAlias :: Maybe Text
    , snapshotTagSet :: [ResourceTag]
    }
  deriving (Show, Read, Eq)

data SnapshotAttribute = SnapshotAttribute
    { snapshotAttributeSnapshotId :: Text
    , snapshotAttributeCreateVolumePermissionItems
        :: [CreateVolumePermissionItem]
    , snapshotAttributeProductCodes :: [ProductCode]
    }
  deriving (Show, Read, Eq)

data SnapshotAttributeRequest
    = SnapshotAttributeRequestCreateVolumePermission
    | SnapshotAttributeRequestProductCodes
  deriving (Show, Read, Eq)

instance ToText SnapshotAttributeRequest where
    toText SnapshotAttributeRequestCreateVolumePermission
        = "createVolumePermission"
    toText SnapshotAttributeRequestProductCodes
        = "productCodes"

data SnapshotStatus
    = SnapshotPending
    | SnapshotCompleted
    | SnapshotError
  deriving (Show, Read, Eq)

deriveFromText "SnapshotStatus" ["pending", "completed", "error"]
