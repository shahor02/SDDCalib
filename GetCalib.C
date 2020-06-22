void GetCalib(int run, const char* path="local:///data/CDBMirror/alice/data/2012/OCDB")
{
  man = AliCDBManager::Instance();
  man->SetRaw(1);
  man->SetRun(run);
  man->SetDrain(path);
  //
  man->Get("GRP/GRP/Data");
  //  man->Get("GRP/Calib/RecoParam");
  //man->Get("GRP/Geometry/Data");
  man->Get("ITS/Align/Data");
  man->Get("ITS/Calib/DriftSpeedSDD");
  man->Get("ITS/Calib/SPDDead");
  man->Get("ITS/Calib/RespSDD");
  man->Get("ITS/Calib/MapsTimeSDD");
  //  
}
