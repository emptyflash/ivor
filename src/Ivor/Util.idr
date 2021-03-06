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
  let os = System.Info.os
  in case os of
       "Windows" => "%APPDATA%/idris"
       _ => "~/.idris"

pkgsDir : String
pkgsDir = 
  idrisAppDir ++ "/packages"

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
  PSuccess <- popen cmd | PError err => (pure $ "Error opening subprocess: " ++ show err)
  PReturn result <- preadAll | PError err => do 
                                                pure $ "Error reading subprocess: " ++ show err
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

mkdirp : String -> Program Int
mkdirp dir =
  system $ "mkdir -p " ++ dir

makeDepsDir : Program String
makeDepsDir = do
  depsDir <- getDepsDir
  mkdirp depsDir
  pure depsDir

idrisLibsDir : Program String
idrisLibsDir =
  trim <$> subprocess "idris --libdir"

makePackagesDir : Program String 
makePackagesDir = do
  mkdirp pkgsDir
  pure pkgsDir

