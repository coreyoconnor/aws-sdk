{-# LANGUAGE FlexibleContexts, RankNTypes #-}

module AWSTests.EC2Tests.SnapshotTests
    ( runSnapshotTests
    )
    where

import qualified Control.Exception.Lifted as E
import Data.Text (Text)
import Test.Hspec

import AWS.EC2
import AWS.EC2.Types
import AWS.EC2.Util (list)
import AWSTests.Util
import AWSTests.EC2Tests.Util

region :: Text
region = "ap-northeast-1"

runSnapshotTests :: IO ()
runSnapshotTests = hspec $ do
    describeSnapshotsTest
    createSnapshotTest
    describeSnapshotAttributeTest

describeSnapshotsTest :: Spec
describeSnapshotsTest = do
    describe "describeSnapshots doesn't fail" $ do
        it "describeSnapshots doesn't throw any exception" $ do
            testEC2 region (describeSnapshots [] [] [] []) `miss` anyConnectionException

createSnapshotTest :: Spec
createSnapshotTest = do
    describe "createSnapshot doesn't fail" $ do
        it "createSnapshot, deleteSnapshot and copySnapshot doesn't any exception" $ do
            testEC2' region (do
                Volume{volumeId = vid}:_ <- list $ describeVolumes [] []
                withSnapshot vid Nothing $ \Snapshot{snapshotId = sid} ->
                    E.bracket (copySnapshot region sid Nothing) deleteSnapshot $ \copied -> do
                        modifySnapshotAttribute copied perm
                        resetSnapshotAttribute copied ResetSnapshotAttributeRequestCreateVolumePermission
                ) `miss` anyConnectionException
  where
    perm = CreateVolumePermission
        { createVolumePermissionAdd = [item]
        , createVolumePermissionRemove = []
        }
    item = CreateVolumePermissionItem
        { createVolumePermissionItemUserId = Nothing
        , createVolumePermissionItemGroup = Just "all"
        }

describeSnapshotAttributeTest :: Spec
describeSnapshotAttributeTest = do
    describe "describeSnapshotAttribute doesn't fail" $ do
        it "describeSnapshotAttribute doesn't throw any exception" $ do
            testEC2' region (do
                snapshots <- list $ describeSnapshots [] [] [] []
                let sid = snapshotId $ head snapshots
                describeSnapshotAttribute sid SnapshotAttributeRequestCreateVolumePermission
                ) `miss` anyConnectionException
