module Ivor.Util

import System.Info

import Effects
import Effect.System
import Effect.StdIO

%access public export

Program : Type -> Type
Program return = 
  Eff return [ SYSTEM, STDIO ]

idrisAppDir : String
idrisAppDir = 
  case System.Info.os of
       "Windows" => "%APPDATA%/idris"
       _ => "~/.idris"

githubUrl : String -> String
githubUrl repo =
  "https://github.com/" ++ repo ++ ".git"

dirFromRepo : String -> String
dirFromRepo repo = pack $ replaceOn '/' '$' $ unpack $ repo

