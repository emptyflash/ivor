module Ivor.Config

import Ivor.Util

import Lightyear
import Lightyear.StringFile

import Tomladris

import Data.SortedMap
import Debug.Trace

%access public export

record Dependency where
  constructor MkDep
  name: String
  pkgName: Maybe String
  version: Maybe String

record Config where
  constructor MkConfig
  name, version, description: String
  dependencies: List Dependency

lookupEither : String -> SortedMap String TomlValue -> Either String TomlValue
lookupEither key map =
  maybeToEither ("No " ++ key ++ " attibute specified") (lookup key map)

lookupTomlString : String -> SortedMap String TomlValue -> Either String String
lookupTomlString key map = do
  TString name <- lookupEither "name" map | _ => Left (key ++ " attibute was the wrong type")
  Right name

lookupKeyValues : String -> SortedMap String TomlValue -> List (String, String)
lookupKeyValues keyPrefix smap = do
  (key, TString val) <- filter (Strings.isPrefixOf keyPrefix . fst) $ toList $ smap 
                        | _ => []
  let strippedKey = ltrim $ pack $ drop (length keyPrefix + 1) $ unpack $ key
  pure (strippedKey, val)

pkglessDep : String -> String -> Dependency
pkglessDep name ver = 
  MkDep name Nothing (Just ver)

mapToConfig : SortedMap String TomlValue -> Either String Config
mapToConfig smap = do
  name <- lookupTomlString "name" smap
  ver <- lookupTomlString "version" smap
  desc <- lookupTomlString "description" smap
  let deps = map (uncurry pkglessDep) $ lookupKeyValues "dependencies" smap
  Right $ MkConfig name ver desc deps

parseConfigFile : String -> Program (Either String Config)
parseConfigFile file = do
  Result contents <- readFile file | FError err => (pure $ Left $ show err)
  let smap = parseToml contents
  pure $ mapToConfig smap
