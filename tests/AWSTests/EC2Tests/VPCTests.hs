{-# LANGUAGE FlexibleContexts, RankNTypes, PatternGuards #-}

module AWSTests.EC2Tests.VPCTests
    ( runVpcTests
    )
    where

import Data.Text (Text)
import Data.List (find)
import Test.Hspec

import AWS.EC2
import AWS.EC2.Types
import AWS.EC2.Util (wait, list)
import AWSTests.Util
import AWSTests.EC2Tests.Util

region :: Text
region = "ap-southeast-1"

runVpcTests :: IO ()
runVpcTests = hspec $ do
    describeVpcsTest
    describeVpnGatewaysTest
    describeInternetGatewaysTest
    describeVpnConnectionsTest
    describeCustomerGatewayTest
    describeInternetGatewaysTest
    describeDhcpOptionsTest
    createVpcTest
    createDhcpOptionsTest
    vpnConnectionTest
    attachAndDetachVpnGatewayTest
    internetGatewayTest

describeVpcsTest :: Spec
describeVpcsTest = do
    describe "describeVpcs doesn't fail" $ do
        it "describeVpcs doesn't throw any exception" $ do
            testEC2 region (describeVpcs [] []) `miss` anyConnectionException

describeVpnGatewaysTest :: Spec
describeVpnGatewaysTest = do
    describe "describeVpnGateways doesn't fail" $ do
        it "describeVpnGateways doesn't throw any exception" $ do
            testEC2 region (describeVpnGateways [] []) `miss` anyConnectionException

describeVpnConnectionsTest :: Spec
describeVpnConnectionsTest = do
    describe "describeVpnConnections doesn't fail" $ do
        it "describeVpnConnections doesn't throw any exception" $ do
            testEC2 region (describeVpnConnections [] []) `miss` anyConnectionException

describeCustomerGatewayTest :: Spec
describeCustomerGatewayTest = do
    describe "describeCustomerGateway doesn't fail" $ do
        it "describeCustomerGateway doesn't throw any exception" $ do
            testEC2 region (describeCustomerGateway [] []) `miss` anyConnectionException

describeInternetGatewaysTest :: Spec
describeInternetGatewaysTest = do
    describe "describeInternetGateways doesn't fail" $ do
        it "describeInternetGateways doesn't throw any exception" $ do
            testEC2 region (describeInternetGateways [] []) `miss` anyConnectionException

createVpcTest :: Spec
createVpcTest = do
    describe "createVpc doesn't fail" $ do
        it "createVpc and deleteVpc doesn't fail" $ do
            vpc <- testEC2' region (createVpc "80.0.0.0/16" Nothing)
            testEC2' region (deleteVpc $ vpcId vpc) `shouldReturn` True

describeDhcpOptionsTest :: Spec
describeDhcpOptionsTest = do
    describe "describeDhcpOptions doesn't fail" $ do
        it "describeDhcpOptions doesn't throw any exception" $ do
            testEC2 region (describeDhcpOptions [] []) `miss` anyConnectionException

createDhcpOptionsTest :: Spec
createDhcpOptionsTest = do
    describe "createDhcpOptions doesn't fail" $ do
        it "createDhcpOptions and deleteDhcpOptions doesn't fail" $ do
            options <- testEC2' region (createDhcpOptions [param])
            testEC2' region (deleteDhcpOptions $ dhcpOptionsId options) `shouldReturn` True
  where
    param = DhcpConfiguration "domain-name" [DhcpValue "example.com"]

vpnConnectionTest :: Spec
vpnConnectionTest = do
    describe "{create,delete}CustomerGateway, {create,delete}VpnGateway and {create,delete}VpnConnection don't fail" $ do
        it "{create,delete}CustomerGateway, {create,delete}VpnGateway and {create,delete}VpnConnection don't throw any exception" $ do
            testEC2' region test `miss` anyConnectionException
  where
    test =
        withCustomerGateway "ipsec.1" "202.202.202.20" 65000 $ \CustomerGateway{customerGatewayId = cgid} ->
            withVpnGateway CreateVpnGatewayTypeIpsec1 Nothing $ \VpnGateway{vpnGatewayId = vpnid} -> do
                VpnConnection{vpnConnectionId = cid} <- withVpnConnection "ipsec.1" cgid vpnid Nothing Nothing return
                wait
                    (\connection -> vpnConnectionState connection == VpnConnectionStateDeleted)
                    (\cid' -> list $ describeVpnConnections [cid'] [])
                    cid

attachAndDetachVpnGatewayTest :: Spec
attachAndDetachVpnGatewayTest = do
    describe "{attach,detach}VpnGateway" $ do
        it "doesn't throw any exception" $ do
            testEC2' region (do
                withVpnGateway CreateVpnGatewayTypeIpsec1 Nothing $ \VpnGateway{vpnGatewayId = vgw} -> do
                    withVpc "10.0.0.0/24" $ \Vpc{vpcId = vpc} -> do
                        attachVpnGateway vgw vpc
                        detachVpnGateway vgw vpc
                        wait (p vpc) desc vgw
                ) `miss` anyConnectionException
  where
    p vpc VpnGateway{vpnGatewayAttachments = as}
        | Just a <- find ((== vpc) . attachmentVpcId) as = attachmentState a == AttachmentStateDetached
        | otherwise = True
    desc vgw = list $ describeVpnGateways [vgw] []

internetGatewayTest :: Spec
internetGatewayTest = do
    describe "{create,delete,attach,detach}InternetGateway" $ do
        it "doesn't throw any exception" $ do
            testEC2' region (
                withVpc "10.0.0.0/24" $ \Vpc{vpcId = vpc} ->
                    withInternetGateway $ \InternetGateway{internetGatewayInternetGatewayId = igw} ->
                        withInternetGatewayAttached igw vpc $ return ()
                ) `miss` anyConnectionException
