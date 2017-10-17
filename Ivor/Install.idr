module Ivor.Install

import Ivor.Util
import Ivor.IPkgOps
import public Ivor.Manifest

%access public export


makePackagesDir : Program String 
makePackagesDir = do
  let pkgDir = idrisAppDir ++ "/packages"
  system $ "mkdir -p " ++ pkgDir
  pure pkgDir

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

installFromGithub : Dependency -> Program Dependency
installFromGithub dep = do
  let repo = name dep
  let maybeVersion = version dep
  pkgsDir <- makePackagesDir
  depsDir <- makeDepsDir
  fullRepo <- updateRepo pkgsDir repo maybeVersion
  Just iPkg <- findIPkgName fullRepo | Nothing => do putStrLn $ "No .ipkg found in " ++ repo
                                                     pure dep
  installIPkg fullRepo iPkg depsDir dep

installFromManifest : String -> Program Int
installFromManifest manifestFile = do
  Right manifest <- parseManifestFile manifestFile | Left err => do putStrLn err; pure 1
  printLn $ map name $ dependencies $ manifest 
  results <- mapE (\t => installFromGithub t) (dependencies manifest)
  let newManifest = record { dependencies = results } manifest
  wd <- pwd
  saveAsIPkgFile wd newManifest
  pure 0

