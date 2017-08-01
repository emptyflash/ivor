module Ivor.Install

import Ivor.Util
import public Ivor.Config

%access public export


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

cloneRepo : String -> String -> String -> Program Int
cloneRepo pkgsDir repoUrl repoDir =
  system $ "cd " ++ pkgsDir ++ " && git clone " ++ repoUrl ++ " " ++ repoDir

fetchRepo : String -> Program Int
fetchRepo fullDir =
  system $ "cd " ++ fullDir ++ " && git fetch"

applyGitVersion : String -> String -> Program Int
applyGitVersion fullDir version =
  system $ "cd " ++ fullDir ++ " && git checkout " ++ version

updateRepo : String -> String -> Maybe String -> Program String
updateRepo pkgsDir repo maybeVersion = do
  let repoDir = dirFromRepo repo
  let fullDir = pkgsDir ++ "/" ++ repoDir
  if !(fileExists fullDir)
     then fetchRepo fullDir
     else cloneRepo pkgsDir (githubUrl repo) repoDir
  case maybeVersion of
       Just version => do applyGitVersion fullDir version; pure ()
       Nothing => pure ()
  pure fullDir

installFromGithub : Dependency -> Program Int
installFromGithub dep = do
  let repo = name dep
  let maybeVersion = version dep
  pkgsDir <- makePackagesDir
  fullRepo <- updateRepo pkgsDir repo maybeVersion
  {- fuck makefiles for now
  if !(fileExists $ fullRepo ++ "/Makefile") 
     then installMakefile fullRepo
     else pure 0
   -}
  Just ipkg <- findIpkgName fullRepo | Nothing => do putStrLn $ "No .ipkg found in " ++ repo
                                                     pure 1
  installIpkg fullRepo ipkg


installConfig : String -> Program Int
installConfig configFile = do
  Right config <- parseConfigFile configFile | Left err => do putStrLn err; pure 1
  printLn $ map name $ dependencies $ config
  results <- mapE (\t => installFromGithub t) (dependencies config)
  pure 0

