module Ivor.Config

import Ivor.Util

import Data.SortedMap

import Yaml
import Lightyear
import Lightyear.StringFile

import Data.SortedMap

%access public export

record Config where
  constructor MkConfig
  name, version, description: String
  dependencies: List String

yamlStrings : List YamlValue -> List String
yamlStrings [] = []
yamlStrings ((YamlString x) :: xs) = x :: yamlStrings xs
yamlStrings (_  :: xs) = yamlStrings xs

configFromMap : SortedMap String YamlValue -> Either String Config
configFromMap object = do
  YamlString name    <- maybeToEither "No name attibute specified" $ lookup "name" object 
                        | _ => Left "Name attribute has wrong type"
  YamlString ver     <- maybeToEither "No version attibute specified" $ lookup "version" object 
                        | _ => Left "Version attribute has wrong type"
  YamlString desc    <- maybeToEither "No description attribute" $ lookup "description" object 
                        | _ => Left "Description attribute has wrong type"
  YamlArray yamlDeps <- maybeToEither "No dependencies specified" $ lookup "dependencies" object 
                        | _ => Left "Dependencies attribute has wrong type"
  let deps = yamlStrings yamlDeps
  pure (MkConfig name ver desc deps)

parseYamlConfig : Parser (Either String Config)
parseYamlConfig = do
  YamlObject object <- yamlToplevelValue | _ => (pure $ Left "Top level value shouldn't be a list")
  pure (configFromMap object)

parseYamlFile : String -> Program (Either String Config)
parseYamlFile file = do
  result <- parseFile dispFileError dispParseError parseYamlConfig file
  pure (join $ result)
where
  dispFileError f e = show e ++ " in " ++ f
  dispParseError f e = "Error parsing " ++ f ++ ": " ++ e
