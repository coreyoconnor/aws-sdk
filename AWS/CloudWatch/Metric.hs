{-# LANGUAGE FlexibleContexts, RankNTypes #-}

module AWS.CloudWatch.Metric
    ( listMetrics
    , getMetricStatistics
    ) where

import Data.Text (Text)
import Data.Time (UTCTime)
import Data.Conduit
import Data.XML.Types (Event)
import Control.Applicative

import AWS.Util
import AWS.CloudWatch.Internal
import AWS.Lib.Query
import AWS.Lib.Parser
import AWS.CloudWatch.Types

dimensionFiltersParam :: [DimensionFilter] -> QueryParam
dimensionFiltersParam =
    ("Dimensions" |.+) . ("member" |.#.) . map filterParams
  where
    filterParams (k, v) =
        [ "Name" |= k
        , "Value" |= v
        ]

listMetrics
    :: (MonadBaseControl IO m, MonadResource m)
    => [DimensionFilter] -- ^ Dimensions
    -> Maybe Text -- ^ MetricName
    -> Maybe Text -- ^ Namespace
    -> Maybe Text -- ^ NextToken
    -> CloudWatch m ([Metric], Maybe Text)
listMetrics ds mn ns nt = cloudWatchQuery "ListMetrics" params $
    (,) <$> members "Metrics" sinkMetric <*> getT "NextToken"
  where
    params =
        [ dimensionFiltersParam ds
        , "MetricName" |=? mn
        , "Namespace" |=? ns
        , "NextToken" |=? nt
        ]

sinkMetric :: MonadThrow m => GLSink Event m Metric
sinkMetric =
    Metric
    <$> members "Dimensions" sinkDimension
    <*> getT "MetricName"
    <*> getT "Namespace"

getMetricStatistics
    :: (MonadBaseControl IO m, MonadResource m)
    => [DimensionFilter]
    -> UTCTime -- ^ StartTime
    -> UTCTime -- ^ EndTime
    -> Text -- ^ MetricName
    -> Text -- ^ Namespace
    -> Int -- ^ Period
    -> [Statistic] -- ^ Statistics
    -> Maybe Text -- ^ Unit
    -> CloudWatch m ([Datapoint], Text) -- ^ Datapoints and Label
getMetricStatistics ds start end mn ns pe sts unit =
    cloudWatchQuery "GetMetricStatistics" params $ (,)
        <$> members "Datapoints" (Datapoint
            <$> getT "Timestamp"
            <*> getT "SampleCount"
            <*> getT "Unit"
            <*> getT "Minimum"
            <*> getT "Maximum"
            <*> getT "Sum"
            <*> getT "Average"
            )
        <*> getT "Label"
  where
    params =
        [ dimensionFiltersParam ds
        , "StartTime" |= timeToText start
        , "EndTime" |= timeToText end
        , "MetricName" |= mn
        , "Namespace" |= ns
        , "Period" |= toText pe
        , "Statistics" |.+ "member" |.#= map stringifyStatistic sts
        , "Unit" |=? unit
        ]
