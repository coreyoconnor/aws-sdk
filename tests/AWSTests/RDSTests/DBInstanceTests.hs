module AWSTests.RDSTests.DBInstanceTests
    ( runDBInstanceTests
    )
    where

import Data.Text (Text)
import Test.Hspec

import AWS.RDS
import AWS.RDS.Types
import AWS.RDS.Util
import AWSTests.Util
import AWSTests.RDSTests.Util

region :: Text
region = "ap-northeast-1"

runDBInstanceTests :: IO ()
runDBInstanceTests = do
    hspec describeDBInstancesTest
    hspec createAndDeleteDBInstanceTest

describeDBInstancesTest :: Spec
describeDBInstancesTest = do
    describe "describeDBInstances doesn't fail" $ do
        it "describeDBInstances doesn't throw any exception" $ do
            testRDS region (describeDBInstances Nothing Nothing Nothing) `miss` anyHttpException

createAndDeleteDBInstanceTest :: Spec
createAndDeleteDBInstanceTest = do
    describe "{create,delete}DBInstance doesn't fail" $ do
        it "{create,delete}DBInstance doesn't any exception" $ do
            testRDS region test `miss` anyHttpException
  where
    test = do
        createDBInstance req
        wait
            (\dbi' -> dbiDBInstanceStatus dbi' == Just "available")
            (\dbiid' -> describeDBInstances (Just dbiid) Nothing Nothing)
            dbiid
        deleteDBInstance dbiid SkipFinalSnapshot
    dbiid = "hspec-test-instance"
    req = CreateDBInstanceRequest
        5
        Nothing Nothing Nothing Nothing
        DBt1micro
        dbiid
        Nothing Nothing [] Nothing
        EngineMySQL
        Nothing
        Nothing
        Nothing
        "test"
        "test"
        Nothing Nothing Nothing Nothing Nothing Nothing []