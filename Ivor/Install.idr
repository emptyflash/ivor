module Ivor.Install

import Ivor.Util

import Effects
import Effect.System
import Effect.StdIO

%access public export

installLocal : String -> Program Int
installLocal x = pure 0

makePackagesDir : Program String 
makePackagesDir = do
  let pkgDir = idrisAppDir ++ "/packages"
  system $ "mkdir -p " ++ pkgDir
  pure pkgDir

fileExists : String -> Program Bool
fileExists dir = do
  result <- system $ "test -e " ++ dir
  pure (result == 0)

findIPkgName : Program String
findIPkgName = ?findIPkgName_rhs

installIPkg : String -> String -> Program Int
installIPkg dir file = system $ "cd " ++ dir ++ " && idris --install " ++ file

installMakefile : String -> Program Int
installMakefile dir = system $ "cd " ++ dir ++ " && make & make install"

cloneRepo : String -> String -> Program String
cloneRepo pkgsDir repo = do
  let repoDir = dirFromRepo repo
  let fullDir = pkgsDir ++ "/" ++ repoDir
  system $ "cd " ++ pkgsDir ++ " && git clone " ++ githubUrl repo ++ " " ++ repoDir
  pure $ fullDir


installFromGithub : String -> Program Int
installFromGithub repo = do
  pkgsDir <- makePackagesDir
  fullRepo <- cloneRepo pkgsDir repo
  putStrLn "worked"
  pure 0
