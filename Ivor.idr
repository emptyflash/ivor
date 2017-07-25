module Ivor

import Ivor.Install
import Ivor.Util

import System


data Command
  = InstallLocal
  | InstallGithub String

parseArgs : List String -> Maybe Command
parseArgs ("install" :: []) = Just InstallLocal
parseArgs ("install" :: repo :: []) = Just (InstallGithub repo)
parseArgs _ = Nothing


processArgs : List String -> Program Int
processArgs args = case parseArgs args of
                        Just InstallLocal => installYaml "./ivor.yaml"
                        Just (InstallGithub repo) => installFromGithub repo
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
