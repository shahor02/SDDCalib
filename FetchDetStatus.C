void FetchDetStatus(int run)
{
  // fetch detector info
  TString cvmfs = gSystem->Getenv("CVMFS");
  TString defPath = "raw://";
  if (!cvmfs.IsNull() && !gSystem->AccessPathName(cvmfs.Data())) {
    cvmfs.Prepend("local://");
    defPath = cvmfs;
  }
  AliCDBManager::Instance()->SetDefaultStorage(defPath.Data());  
  printf("Set Defauls CDB path to %s\n",cvmfs.Data());
  
  AliCDBManager::Instance()->SetRun(run); 
  AliCDBEntry* entry = AliCDBManager::Instance()->Get("GRP/GRP/Data");
  AliGRPObject* grpData = dynamic_cast<AliGRPObject*>(entry->GetObject()); 
  if (!grpData) {printf("Failed to get GRP data for run",runNumber); return;}
  Int_t activeDetectors = grpData->GetDetectorMask(); 
  TString detStr = AliDAQ::ListOfTriggeredDetectors(activeDetectors);
  //
  TString st = Form("TPC%d;SPD%d;SDD%d;SSD%d;",
		    detStr.Contains("TPC")    ? 1:0,
		    detStr.Contains("ITSSPD") ? 1:0,
		    detStr.Contains("ITSSDD") ? 1:0,
		    detStr.Contains("ITSSSD") ? 1:0);
  ofstream myfile;
  myfile.open (Form("_detStatus_%d",run));
  myfile << st.Data();
  myfile.close();
}
