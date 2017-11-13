module Ivor.Manifest

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

record Manifest where
  constructor MkManifest
  name, version, description : String
  dependencies : List Dependency
  sourceDirectory, main, executable, opts : Maybe String
  modules : Maybe (List String)

lookupEither : String -> SortedMap String TomlValue -> Either String TomlValue
lookupEither key map =
  maybeToEither ("No " ++ key ++ " attibute specified") (lookup key map)

requireTomlString : String -> SortedMap String TomlValue -> Either String String
requireTomlString key map = do
  TString name <- lookupEither "name" map | _ => Left (key ++ " attibute was the wrong type")
  Right name

lookupTomlString : String -> SortedMap String TomlValue -> Maybe String
lookupTomlString key smap = do
  TString name <- lookup key smap | _ => Nothing
  Just name

lookupKeyValues : String -> SortedMap String TomlValue -> List (String, String)
lookupKeyValues keyPrefix smap = do
  (key, TString val) <- filter (Strings.isPrefixOf keyPrefix . fst) $ toList $ smap 
                        | _ => []
  let strippedKey = ltrim $ pack $ drop (length keyPrefix + 1) $ unpack $ key
  pure (strippedKey, val)

onlyString : TomlValue -> Maybe String
onlyString (TString s) = Just s
onlyString _ = Nothing

lookupList : String -> SortedMap String TomlValue -> Maybe (List String)
lookupList key smap = do
  TArray list <- lookup key smap | _ => Nothing
  sequence $ map onlyString list

pkglessDep : String -> String -> Dependency
pkglessDep name ver = 
  MkDep name Nothing (Just ver)

mapToManifest : SortedMap String TomlValue -> Either String Manifest
mapToManifest smap = do
  name <- requireTomlString "name" smap
  ver <- requireTomlString "version" smap
  desc <- requireTomlString "description" smap
  let deps = map (uncurry pkglessDep) $ lookupKeyValues "dependencies" smap
  let sourceDirectory = lookupTomlString "sourceDirectory" smap
  let main = lookupTomlString "main" smap
  let executable = lookupTomlString "executable" smap
  let opts = lookupTomlString "opts" smap
  let modules = lookupList "modules" smap
  Right $ MkManifest name ver desc deps sourceDirectory main executable opts modules

parseManifestFile : String -> Program (Either String Manifest)
parseManifestFile file = do
  Result contents <- readFile file | FError err => (pure $ Left $ show err)
  putStrLn contents
  let smap = parseToml contents
  pure $ mapToManifest smap
