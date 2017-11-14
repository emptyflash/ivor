module Ivor

import Ivor.Install
import Ivor.Manifest
import Ivor.Util

import System


data Command
  = InstallLocal
  | InstallGithub String
  | Repl
  | Build
  | Test

parseArgs : List String -> Maybe Command
parseArgs ("install" :: []) = Just InstallLocal
parseArgs ("repl" :: []) = Just Repl
parseArgs ("build" :: []) = Just Build
parseArgs ("test" :: []) = Just Test
parseArgs ("install" :: repo :: []) = Just (InstallGithub repo)
parseArgs _ = Nothing

data IdrisFlag
  = ReplFlag
  | BuildFlag
  | TestFlag

flagToString : IdrisFlag -> String
flagToString ReplFlag = "--repl"
flagToString BuildFlag = "--build"
flagToString TestFlag = "--testpkg"

doIdrisCommand : IdrisFlag -> Program Int
doIdrisCommand command = do
  Right manifest <- parseManifestFile "./ivor.toml" | Left err => do putStrLn err; pure 1
  depsDir <- getDepsDir
  Effect.System.system $ "IDRIS_LIBRARY_PATH=" ++ depsDir ++ " idris " ++ flagToString command ++ " " ++ (name manifest) ++ ".ipkg" 

idrisRepl : Program Int
idrisRepl = doIdrisCommand ReplFlag

idrisBuild : Program Int
idrisBuild = doIdrisCommand BuildFlag

idrisTest : Program Int
idrisTest = doIdrisCommand TestFlag

-- We need all the base idris libs in our deps dir
copyIdrisLibs : Program Int
copyIdrisLibs = do
  depsDir <- getDepsDir
  libsDir <- idrisLibsDir
  system $ "cp -R " ++ libsDir ++ "/base " ++ depsDir
  system $ "cp -R " ++ libsDir ++ "/prelude " ++ depsDir
  system $ "cp -R " ++ libsDir ++ "/contrib " ++ depsDir
  system $ "cp -R " ++ libsDir ++ "/effects " ++ depsDir

processArgs : List String -> Program Int
processArgs args = case parseArgs args of
                        Just InstallLocal => do
                          pkgsDir <- makePackagesDir
                          depsDir <- makeDepsDir
                          copyIdrisLibs
                          installFromManifest "./ivor.toml"
                        Just Repl => idrisRepl
                        Just Build => idrisBuild
                        Just (InstallGithub repo) => do
                          pkgsDir <- makePackagesDir
                          depsDir <- makeDepsDir
                          copyIdrisLibs
                          installFromGithub (MkDep repo Nothing Nothing)
                          pure 0
                        Nothing => do 
                          putStrLn "Unrecognized command. Usage: ivor install or ivor install user/repo" 
                          pure 1

program : Program Int
program = do 
  (_ :: args) <- getArgs
  processArgs args

namespace Main
  main : IO ()
  main = do
    result <- run $ program 
    putStrLn "Done."
    exit result
