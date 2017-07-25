module Ivor.Install

import Ivor.Util

import Yaml

import Effects
import Effect.System
import Effect.StdIO

%access public export

installYaml : String -> Program Int
installYaml yamFile = pure 0

makePackagesDir : Program String 
makePackagesDir = do
  let pkgDir = idrisAppDir ++ "/packages"
  system $ "mkdir -p " ++ pkgDir
  pure pkgDir

fileExists : String -> Program Bool
fileExists dir = do
  result <- system $ "test -e " ++ dir
  pure (result == 0)

findIpkgName : String -> Program (Maybe String)
findIpkgName dir = do
  files <- ls dir
  let pkgs = List.filter (Strings.isSuffixOf ".ipkg") files
  pure (head' pkgs)

installIpkg : String -> String -> Program Int
installIpkg dir file = system $ "cd " ++ dir ++ " && idris --install " ++ file

installMakefile : String -> Program Int
installMakefile dir = system $ "cd " ++ dir ++ " && make install"

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
  if !(fileExists $ fullRepo ++ "/Makefile") 
     then installMakefile fullRepo
     else do
       Just ipkg <- findIpkgName fullRepo | Nothing => do putStrLn $ "No .ipkg found for " ++ repo
                                                          pure 1
       installIpkg fullRepo ipkg
