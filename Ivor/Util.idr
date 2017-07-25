module Ivor.Util

import public Ivor.Subprocess

import System.Info

import public Effects
import public Effect.System
import public Effect.StdIO

%access public export

Program : Type -> Type
Program return = 
  Eff return [ SYSTEM, STDIO, SUBPROCESS () ]

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

subprocess : String -> Eff String [ SUBPROCESS () ]
subprocess cmd = do 
  PSuccess <- popen cmd | PError err => (pure $ "Error listing files in directory: " ++ show err)
  PReturn result <- preadAll | PError err => do 
                                                pure $ "Error reading stdout: " ++ show err
  pure result

ls : String -> Program (List String)
ls dir = do
  result <- subprocess $ "ls " ++ dir
  pure $ join $ map words $ lines $ result

