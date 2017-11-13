module Ivor.Install

import Ivor.Util as Util
import Ivor.IPkgOps
import public Ivor.Manifest

%access public export


installMakefile : String -> Program Int
installMakefile dir = system $ "cd " ++ dir ++ " && make install"

cloneRepo : String -> String -> Program Int
cloneRepo repoUrl repoDir =
  system $ "cd " ++ Util.pkgsDir ++ " && git clone " ++ repoUrl ++ " " ++ repoDir

fetchRepo : String -> Program Int
fetchRepo fullDir =
  system $ "cd " ++ fullDir ++ " && git fetch"

applyGitVersion : String -> String -> Program Int
applyGitVersion fullDir version =
  system $ "cd " ++ fullDir ++ " && git checkout " ++ version

updateRepo : String -> Maybe String -> Program String
updateRepo repo maybeVersion = do
  let repoDir = dirFromRepo repo
  let fullDir = Util.pkgsDir ++ "/" ++ repoDir
  if !(fileExists fullDir)
     then fetchRepo fullDir
     else cloneRepo (githubUrl repo) repoDir
  case maybeVersion of
       Just version => do applyGitVersion fullDir version; pure ()
       Nothing => pure ()
  pure fullDir

installFromGithub : Dependency -> Program Dependency
installFromGithub dep = do
  let repo = name dep
  let maybeVersion = version dep
  fullRepo <- updateRepo repo maybeVersion
  depsDir <- getDepsDir
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

