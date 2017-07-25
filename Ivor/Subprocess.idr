module Ivor.Subprocess

import Effects

%access public export


data ProcessResult = SUCCESS | RESULT

data ProcessReturn : (pr: ProcessResult) -> (ty: Type) -> Type where
  PSuccess : ProcessReturn SUCCESS ty
  PReturn : ty -> ProcessReturn RESULT ty
  PError : FileError ->  ProcessReturn pr ty

Success : Type
Success = ProcessReturn SUCCESS ()

Return : Type -> Type
Return ty = ProcessReturn RESULT ty

data ProcessHandle = PH File

calcResourceType : ProcessReturn a b -> Type
calcResourceType (PError err) = ()
calcResourceType _ = ProcessHandle

data SubprocessE : Effect where
  POpen : String -> sig SubprocessE Success () (\res => calcResourceType res)
  PClose : sig SubprocessE () ProcessHandle ()
  PRead : sig SubprocessE (Return String) ProcessHandle ProcessHandle
  PReadAll : sig SubprocessE (Return String) ProcessHandle ()

implementation Handler SubprocessE IO where
  handle () (POpen cmd) k = do
    Right file <- popen cmd Read | Left err => k (PError err) ()
    k PSuccess (PH file)

  handle (PH file) PClose k = do
    pclose file
    k () ()

  handle (PH file) PRead k = do
    Right line <- fGetLine file | Left err => k (PError err) (PH file)
    k (PReturn line) (PH file)

  handle (PH file) PReadAll k = loop "" 
    where
      loop acc = 
        if !(fEOF file) then do 
                          pclose file
                          k (PReturn acc) ()
                        else do
                          result <- fGetLine file 
                          case result of
                               Right line => loop (acc ++ line)
                               Left err => k (PError err) ()

SUBPROCESS: (ty : Type) -> EFFECT
SUBPROCESS t = MkEff t SubprocessE

popen : (s: String) -> Eff Success [ SUBPROCESS () ] (\res => [ SUBPROCESS (calcResourceType res) ])
popen cmd = call $ POpen cmd

pclose : Eff () [ SUBPROCESS (ProcessHandle) ] [ SUBPROCESS () ]
pclose = call PClose

pread : Eff (Return String) [ SUBPROCESS (ProcessHandle) ]
pread = call PRead

preadAll : Eff (Return String) [ SUBPROCESS (ProcessHandle) ] [ SUBPROCESS () ]
preadAll = call PReadAll
