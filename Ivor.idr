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

parseArgs : List String -> Maybe Command
parseArgs ("install" :: []) = Just InstallLocal
parseArgs ("repl" :: []) = Just Repl
parseArgs ("build" :: []) = Just Build
parseArgs ("install" :: repo :: []) = Just (InstallGithub repo)
parseArgs _ = Nothing

idrisRepl : Program Int
idrisRepl = do
  Right manifest <- parseManifestFile "./ivor.toml" | Left err => do putStrLn err; pure 1
  depsDir <- getDepsDir
  Effect.System.system $ "idris --repl " ++ name manifest ++ ".ipkg --idrispath " ++ depsDir

idrisBuild : Program Int
idrisBuild = do
  Right manifest <- parseManifestFile "./ivor.toml" | Left err => do putStrLn err; pure 1
  depsDir <- getDepsDir
  Effect.System.system $ "idris --build " ++ name manifest ++ ".ipkg --idrispath " ++ depsDir

processArgs : List String -> Program Int
processArgs args = case parseArgs args of
                        Just InstallLocal => installFromManifest "./ivor.toml"
                        Just Repl => idrisRepl
                        Just Build => idrisBuild
                        Just (InstallGithub repo) => do
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
