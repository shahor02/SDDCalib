
int moveList[] = {
  2450,
  2451
}; // SDDid*10+side

AliCDBEntry* LoadMap(const char* src);
void CreateObj(TObject *obj,int firstrun,int lastrun,const char* path,const char *location, const char* comment="");

void MoveMaps(const char* fromMap,
	      const char* toMap,
	      int rMin=-1,int rMax=-1,
	      const char* outPath="local://")
{
  AliCDBEntry* entFrom = LoadMap(fromMap);
  AliCDBEntry* entTo   = LoadMap(toMap);
  //
  TObjArray* arrFrom = (TObjArray*)entFrom->GetObject();
  TObjArray* arrTo   = (TObjArray*)entTo->GetObject();
  //
  int nMaps = sizeof(moveList)/sizeof(int);
  AliCDBMetaData* meta = entTo->GetMetaData();
  TString comment = meta->GetComment();
  if (rMin<0 && rMax<0) {
    AliCDBId& id = entFrom->GetId();
    rMin = id.GetFirstRun();
    rMax = id.GetLastRun();
  }
  comment += " bricolage of:";
  for (int i=0;i<nMaps;i++) {
    int sddID   = moveList[i]/10;
    int sddSide = moveList[i]%10;
    TString sddName = Form("DriftTimeMap_%3d_%d",sddID,sddSide);
    printf("Moving map %d: %s\n",i,sddName.Data());
    AliITSCorrMap1DSDD* mapSrc = (AliITSCorrMap1DSDD*)arrFrom->FindObject(sddName.Data());
    if (!mapSrc) {
      printf("Failed to find source map %d = %s\n",moveList[i],sddName.Data());
      exit(1);
    }
    AliITSCorrMap1DSDD* mapDest = (AliITSCorrMap1DSDD*)arrTo->FindObject(sddName.Data());
    if (!mapDest) {
      printf("Failed to find destination map %d = %s\n",moveList[i],sddName.Data());
      exit(1);
    }
    //
    int idx = arrTo->IndexOf(mapDest);
    arrTo->RemoveAt(idx);
    arrTo->AddAt(mapSrc,idx);
    printf("Added %s at slot %d\n",sddName.Data(),idx);
    delete mapDest;
    comment += Form(" %3d_%d",sddID,sddSide);
  }
  //
  CreateObj(arrTo,rMin,rMax,"ITS/Calib/MapsTimeSDD",outPath,comment.Data());
}


AliCDBEntry* LoadMap(const char* src)
{
  TFile* fl = TFile::Open(src);
  if (!fl) {
    printf("no file %s\n");
    exit(1);
  }
  AliCDBEntry* ent = (AliCDBEntry*) fl->Get("AliCDBEntry");
  if (!ent) {
    printf("no entry in %s\n");
    exit(1);
  }
  return ent;
}

void CreateObj(TObject *obj,int firstrun,int lastrun,const char* path,const char *location, const char* comment)
{
  AliCDBManager* man = AliCDBManager::Instance();
  man->UnsetDefaultStorage();
  man->SetDefaultStorage(location);
  AliCDBMetaData* md = new AliCDBMetaData();
  md->SetResponsible("Ruben Shahoyan");
  md->SetComment(comment);
  AliCDBId id(path,firstrun,lastrun<0 ? (AliCDBRunRange::Infinity()) : lastrun);
  //AliCDBStorage* st = man->GetStorage("local//.");
  man->Put(obj,id,md); 
  //
}
