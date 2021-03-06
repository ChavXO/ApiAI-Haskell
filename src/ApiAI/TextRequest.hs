{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE DeriveAnyClass    #-}
{-# LANGUAGE NamedFieldPuns    #-}

module ApiAI.TextRequest where

import ApiAI.Response
import Control.Lens hiding (contexts, Context)
import Data.Aeson
import qualified Data.ByteString.Char8 as C
import qualified Data.ByteString.Lazy.Char8 as CL
import qualified Data.ByteString.Lazy.Internal as I
import qualified Data.ByteString.Lazy as L
import Data.Scientific
import qualified Data.Text as T
import Network.Wreq
import Data.Aeson (object, (.=), encode)

baseURL = "https://api.api.ai/v1/query?"

data Client = Client
  { accessToken :: String
  , subscriptionKey :: String
  } deriving (Show, Eq)

parseAIResponse :: Response L.ByteString -> AIResponse
parseAIResponse res =
  maybe (error "Failed to parse JSON") id (decode $ res ^. responseBody)

data TextRequest = TextRequest
  { query :: String
  , v :: String
  , confidence :: Maybe Scientific
  , sessionId :: String
  , lang :: String
  , context :: Maybe [Context]
  , resetContext :: Maybe Bool
  , entities :: Maybe [String]
  , timezone :: Maybe String
  } deriving (Show)

client token key = Client { accessToken = token
                          , subscriptionKey = key
                          }

buildAIRequest :: Client -> TextRequest -> Options
buildAIRequest client textRequest =
  defaults
    & header "Authorization"             .~ [C.pack $ "Bearer " ++ (accessToken client)]
    & header "ocp-apim-subscription-key" .~ [C.pack $ subscriptionKey client]
    & param  "query"                     .~ [T.pack $ query textRequest]
    & param  "v"                         .~ [T.pack $ v textRequest]
    & param  "sessionId"                 .~ [T.pack $ sessionId textRequest]
    & param  "lang"                      .~ [T.pack $ lang textRequest]

withClient :: Client -> TextRequest -> IO AIResponse
withClient client textRequest = do
                      r <- getWith (buildAIRequest client textRequest) baseURL
                      putStrLn "Got request"
                      --CL.putStrLn $ r ^. responseBody
                      return (parseAIResponse r)
