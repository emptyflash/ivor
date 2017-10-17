module Ivor.Util

import public Ivor.Subprocess

import System.Info

import public Effects
import public Effect.System
import public Effect.StdIO
import public Effect.File

%access public export

Program : Type -> Type
Program return = 
  Eff return [ SYSTEM, STDIO, SUBPROCESS (), FILE () ]

idrisAppDir : String
idrisAppDir = 
  case System.Info.os of
       "Windows" => "%APPDATA%/idris"
       _ => "~/.idris"

githubUrl : String -> String
githubUrl repo =
  "https://github.com/" ++ repo ++ ".git"

dirFromRepo : String -> String
dirFromRepo repo = pack $ replaceOn '/' '_' $ unpack $ repo

fileExists : String -> Program Bool
fileExists dir = do
  result <- system $ "test -e " ++ dir
  pure (result == 0)

subprocess : String -> Eff String [ SUBPROCESS () ]
subprocess cmd = do 
  PSuccess <- popen cmd | PError err => (pure $ "Error listing files in directory: " ++ show err)
  PReturn result <- preadAll | PError err => do 
                                                pure $ "Error reading stdout: " ++ show err
  pure result

pwd : Program String
pwd = do
  result <- subprocess $ "pwd"
  pure $ trim result

ls : String -> Program (List String)
ls args = do
  result <- subprocess $ "ls " ++ args
  pure $ join $ map words $ lines $ result

listAllIdrisFiles : String -> Program (List String)
listAllIdrisFiles dir =
  ls $ dir ++ "/*.idr " ++ dir ++ "/**/*.idr"

maybeToList : Maybe a -> List a
maybeToList (Just a) = [a]
maybeToList _ = []

getDepsDir : Program String
getDepsDir = do 
  wd <- pwd
  pure $ wd ++ "/deps"

makeDepsDir : Program String
makeDepsDir = do
  depsDir <- getDepsDir
  system $ "mkdir -p " ++ depsDir
  pure depsDir
