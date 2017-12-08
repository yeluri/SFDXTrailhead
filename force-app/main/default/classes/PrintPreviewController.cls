/*
@author: Satya (CommScope)
@date created: 29 Aug 2017

@Desc: Print Preview for Lightning Record Pages
*/
public without sharing class PrintPreviewController {
        public User usr {get;set;}
        public String paramId {get;set;}
        public String sobjectName {get;set;}
        //public sObject sObj {get;set;}
        public List<String> recTypeIds {get;set;}
        public boolean flag{get;set;}
        public Id rc{get;set;}
        public List<layoutSectionsWrapper> layoutItems{get;set;}
        public String totalItems{get;set;}
        public String totalRLItems{get;set;}
        //public Case[] c{get;set;}
        //public Opportunity[] opp{get;set;}
        public Map<String, Schema.SObjectField> fieldMap{get;set;}
        public Schema.SObjectType caseSchema {get;set;}
        public Schema.SobjectType objSchema{get;set;}
        public Map<String, Schema.SObjectType> schemaMap{get;set;}
        //public Case objCase{get;set;}
        public SObject sObj{get;set;}
        public Integer mapKey{get;set;}

        //Layout Sections
        public List<layoutSectionsWrapper> lstSections{get;set;}//Root - comes from JS
        public Set<String> setsections{get;set;} //Set 
        public Map<Integer, HeaderWrapper> mapOuter{get;set;}//Holds Key, Section Label
        public Map<String,String> sectionFieldValuesMap{get;set;}//mapValues- Field Api and Value
        public Map<Integer, List<DataWrapper>> mapInner{get;set;}//Holds fieldapi, type and label

        //Layout Related List Properties
        public Map<Integer, String> mapRlOuter{get;set;}
        public Map<Integer, List<SObject>> mapRlInner{get;set;}
        public Map<Integer, List<String>> mapRlFields{get;set;}
        //public Map<Integer, List<String>> mapRlLabels{get;set;}
        public Map<String, String> mapRlLabels{get;set;}

        //Exist in CSCommScopeUtil
        public static Map<String, Map<String, Schema.SObjectField>> fieldDescribeCache = 
                        new Map<String, Map<String, Schema.SObjectField>>();

        public PrintPreviewController() {
                //System.debug(LoggingLevel.INFO, 'Coming..........');
                paramId = Apexpages.currentPage().getParameters().get('id');
                Schema.SobjectType sobjtype = Id.valueof(paramID).getSobjectType();
                Schema.Describesobjectresult sobjectdes = sobjtype.getDescribe();
                 sobjectName = sobjectdes.getName();
                 //Newly added on 2 Nov 2017 - Begin
                 SObject parent = Database.query('select recordType.DeveloperName from ' + String.valueOf(sobjtype)
                                + ' where Id = :paramId');
                 String recTypeDevName = (String) parent.getSobject('RecordType').get('DeveloperName');
                 Id recTypeid = [select Id from RecordType where SObjectType = :String.valueOf(sobjtype)
                                and DeveloperName = :recTypeDevName].Id;
                        System.debug('Record Type Id: ' + recTypeid);  

                        recTypeIds = new List<String>();   
                        if(recTypeid != null) 
                        recTypeIds.add('\'' + recTypeid + '\'');
                        else
                        recTypeIds = null;
                 //--End

                 //Old Code -- Commented 
                 /*RecordType[] RT = [select id, name, developername from recordType where sobjecttype=: sobjectName];

                if (RT.Size() > 0){
                recTypeIds = new List<String>();
                if (sobjectName == 'Case'){
                Case[] c = database.query(buildQuery(sobjectdes) + ' Where Id =: paramId');
                if (c.size()>0){
                recTypeIds.add('\'' + c[0].RecordTypeId + '\'');
                }
                }

                if (sobjectName == 'Opportunity'){
                Opportunity[] opp = database.query(buildQuery(sobjectdes) + ' Where Id = : paramId');
                if (opp.size()>0){
                recTypeIds.add('\'' + opp[0].RecordTypeId + '\'');
                }
                }
                }

                else
                recTypeIds = null;*/

        }

        public void loadInfo(){
            mapKey = 1;
            System.debug(LoggingLevel.INFO, 'Sections and Items -- : ' + totalItems);
            System.debug(LoggingLevel.INFO, 'RelatedLists and Items -- : ' + totalRLItems);

            //System.debug(LoggingLevel.INFO, 'Sections and Items Deserialize -- : ' + JSON.deserialize(totalItems, List<innerWrapperClass>.class));

            /******************** Layout Sections ******************/
            String strFieldVal='';
            //String buildFieldsToQuery='';
            sectionFieldValuesMap = new Map<String, String>();
            lstSections = (List<layoutSectionsWrapper>)JSON.deserialize(totalItems, List<layoutSectionsWrapper>.class);
            //System.debug(LoggingLevel.INFO, lstSections);

            //for(layoutSectionsWrapper str:lstSections){
            //System.debug(LoggingLevel.INFO, 'Array from JS: ');
            //System.debug(LoggingLevel.INFO, str + '  ' + str.sectionName + '  ' + str.fieldLabel + '  ' + str.fieldApi + '  ' + str.fieldType);
            //}

            //Handle Case Object
            //if(sobjectName == 'Case'){
            schemaMap = Schema.getGlobalDescribe();
            //caseSchema = schemaMap.get('Case');
            caseSchema = schemaMap.get(sobjectName);
                fieldMap = caseSchema.getDescribe().fields.getMap();
                //objCase = putFieldApiWithReference(lstSections, 'Case');
                //objCase = putFieldApiWithReference(lstSections, sobjectName);
                sObj = putFieldApiWithReference(lstSections, sobjectName);
            System.debug('sobj>>>>' + sobj);
            //}
            // Get Section Names and Cols per section in mapOuter
            setsections =new Set<String>();
            mapOuter = new Map<Integer, HeaderWrapper>();
            for(layoutSectionsWrapper str:lstSections)
            {
                if (!setsections.contains(str.sectionName) && str.fieldType != 'VisualforcePage'){
                mapOuter.put(mapKey, new HeaderWrapper(str.sectionName, Integer.valueOf(str.cols)));
                mapKey++;
            }
            setsections.add(str.sectionName);
            }

            //System.debug(LoggingLevel.INFO, setsections);
            System.debug(LoggingLevel.INFO, 'mapOuter>>> ' + mapOuter);

            // Fetch Case values and put in Map<FieldAPI, FieldValue>
            String temp;
            //if(objCase != null){
            if(sObj != null){
                for(layoutSectionsWrapper item: lstSections){
                //System.debug(LoggingLevel.INFO, item.cols + '--' + item.sectionName + '--' + item.fieldLabel + '--' + item.fieldtype + '--' + item.fieldAPI);
                    if(item.fieldType=='field'){
                      
                     temp='';
                            Schema.DisplayType fielddataType = fieldMap.get(item.fieldAPI).getDescribe().getType();
                          //System.debug(LoggingLevel.INFO, 'FieldAPI>>>' + item.fieldAPI + String.valueOf(fielddataType));
                            //System.debug(LoggingLevel.Info, 'Display Value: ' +String.valueOf(c[0].get(item.fieldAPI)));
                            //System.debug(LoggingLevel.Info, 'Display Type: ' + fielddataType);
                            if (String.valueOf(fielddataType) == 'reference'){
                            temp = item.fieldAPI;
                            //System.debug(LoggingLevel.INFO, 'temp>>>>' + temp);
                            if (temp.endsWith('Id') && temp != 'ParentId'){
                            temp = temp.substring(0, temp.indexOf('Id',0));
                            strFieldVal = sObj.getSobject(temp) == null ? '' : String.valueOf(sObj.getSobject(temp).get('Name'));
                            }
                            if (temp.endsWith('__c')){
                            temp = temp.substring(0, temp.indexOf('__c',0));
                            temp = temp + '__r';
                            strFieldVal = sObj.getSobject(temp) == null ? '' : String.valueOf(sObj.getSobject(temp).get('Name'));
                            }
                            if (temp == 'ParentId'){
                            temp = temp.substring(0, temp.indexOf('Id',0));
                            if (sobjectName == 'Case')
                            strFieldVal = sObj.getSobject(temp) == null ? '' : String.valueOf(sObj.getSobject(temp).get('CaseNumber'));
                            else
                            strFieldVal = sObj.getSobject(temp) == null ? '' : String.valueOf(sObj.getSobject(temp).get('Name'));
                            }

                            sectionFieldValuesMap.put(item.fieldAPI, strFieldVal);

                         }else{//System.debug(LoggingLevel.INFO, 'Error FieldAPI>>>' + item.fieldAPI + String.valueOf(fielddataType));
                             if(String.valueOf(sObj.get(item.fieldAPI)) == null)
                            sectionFieldValuesMap.put(item.fieldAPI, '');
                            else{
                                if (item.fieldAPI == 'BillingAddress'){
                                Address addr = (Address)sObj.get(item.fieldAPI);

                                  System.debug(LoggingLevel.INFO, 'BillingAddress>>>' + addr.getCity());
                                }
                                strFieldVal = String.valueOf(sObj.get(item.fieldAPI));
                                //strFieldVal = strFieldVal.replace(' ', '&nbsp;');
                                strFieldVal = strFieldVal.replace('\n', '<br>');
                                 //if(sectionFieldValuesMap.containsKey(item.fieldAPI))
                                //sectionFieldValuesMap.put(item.fieldAPI, sectionFieldValuesMap.get(item.fieldAPI) + ' ' +strFieldVal);            
                                //else
                                sectionFieldValuesMap.put(item.fieldAPI, strFieldVal);
                            }

                    }
                    }
                }

                //System.debug(LoggingLevel.INFO, 'sectionFieldValuesMap>>>> ' + sectionFieldValuesMap);
                //for(String str:sectionFieldValuesMap.KeySet()){
                //System.debug(LoggingLevel.INFO, str + ' ' + sectionFieldValuesMap.get(str));
                //}

            }
            else{
            //Error Message
            }

            //Fill the mapInner 
            fillMapInner(lstSections); //Holds fieldLabel, fieldApi and Type attributes

            /******************** Related List Sections ******************/
            /************************************************************/
            List<layoutRelatedWrapper> lstRelated = (List<layoutRelatedWrapper>)JSON.deserialize(totalRLItems, List<layoutRelatedWrapper>.class);
            //System.debug(LoggingLevel.INFO, 'lstRelated: ' + lstRelated);

            for(layoutRelatedWrapper item: lstRelated){
            System.debug(LoggingLevel.INFO, item.rlLabel + '--' + item.rlSobject + '--' + item.rlChildName + '--' + item.rlKeyfield + '--' + item.rlColfieldLabel + '--' + item.rlColfieldApi);
            }

            /****** Fill MapRLOuter *****************/
            setsections.clear();
            mapKey=1;
            mapRlOuter = new Map<Integer, String>();
            for(layoutRelatedWrapper str:lstRelated){
                if (!setsections.contains(str.rlLabel)){
                    /*if (str.rlSobject != 'OpenActivity' && str.rlSobject != 'ActivityHistory' 
                    && str.rlSobject != 'CombinedAttachment' && str.rlSobject != 'ProcessInstanceHistory' 
                    && str.rlSobject != 'CaseArticle' && str.rlSobject != 'AttachedContentNote' 
                    && str.rlSobject != 'AttachedContentDocument')
                    */
                    if (str.rlSobject != 'CaseArticle' && str.rlSobject != 'EmailMessage'
                    && str.rlSobject != 'ActivityHistory' && str.rlSobject != 'CaseHistory'
                    && str.rlSobject != 'AttachedContentDocument')
                    {
                    //System.debug(LoggingLevel.INFO, 'mapRlOuter Elements' + mapRlOuter);
                    mapRlOuter.put(mapKey, str.rlLabel);
                    mapKey++;
                    }
                }
                setsections.add(str.rlLabel);
            }

            System.debug(LoggingLevel.INFO, 'mapRlOuter : ' + mapRlOuter);


            /********* Fill MapRLInner ************/
            setsections.clear();
            Map<Integer, List<RLInternalDataWrapper>> mapInternalStore = new Map<Integer, List<RLInternalDataWrapper>>();
            List<RLInternalDataWrapper> lstForMapInner=new List<RLInternalDataWrapper>();
            List<RLInternalDataWrapper> lstData;
            mapKey=1;

            for(layoutRelatedWrapper str: lstRelated){
                /*if (str.rlSobject != 'OpenActivity' && str.rlSobject != 'ActivityHistory' 
                && str.rlSobject != 'CombinedAttachment' && str.rlSobject != 'ProcessInstanceHistory'
                && str.rlSobject != 'CaseArticle' && str.rlSobject != 'AttachedContentNote' 
                && str.rlSobject != 'AttachedContentDocument'){
                */
                if (str.rlSobject != 'CaseArticle' && str.rlSobject != 'EmailMessage'
                && str.rlSobject != 'ActivityHistory' && str.rlSobject != 'CaseHistory'
                && str.rlSobject != 'AttachedContentDocument'){
                    //System.debug(LoggingLevel.INFO, 'Each element in lstRelated >>>>' + str.rlLabel);
                    if (setsections.contains(str.rlLabel)){
                        lstData = new List<RLInternalDataWrapper>();
                        lstData.add(new RLInternalDataWrapper(str.rlLabel, str.rlSobject, str.rlChildName, str.rlKeyfield, str.rlColfieldLabel, str.rlColfieldApi));
                        lstForMapInner.addAll(lstData);
                    }
                    else{
                        lstData = new List<RLInternalDataWrapper>();
                        if(mapKey==1 && lstForMapInner.size()>0){
                            //System.debug(LoggingLevel.INFO,'mapInternalStore  >>> ' + mapKey + lstForMapInner);
                            mapInternalStore.put(mapKey, lstForMapInner);
                            mapKey++;
                            //System.debug(LoggingLevel.INFO,'mapInternalStore  >>> ' + mapKey + mapInternalStore);

                    }
                    else{
                            //System.debug(LoggingLevel.INFO, 'Suspected area: ' + mapKey);
                            //System.debug(LoggingLevel.INFO, 'Suspected area--: ' + mapInternalStore);
                            if(mapKey!=1 && !mapInternalStore.containsKey(mapKey)){
                            //System.debug(LoggingLevel.INFO,'mapInternalStore >>> ' + mapKey + lstForMapInner);
                            mapInternalStore.put(mapKey, lstForMapInner);
                            //System.debug(LoggingLevel.INFO,'mapInternalStore >>> ' + mapKey + mapInternalStore);
                            mapKey++;
                    }
                    }
                        lstForMapInner = new List<RLInternalDataWrapper>();
                        lstData.add(new RLInternalDataWrapper(str.rlLabel, str.rlSobject, str.rlChildName, str.rlKeyfield, str.rlColfieldLabel, str.rlColfieldApi));
                        lstForMapInner.addAll(lstData);
                        //System.debug(LoggingLevel.INFO, 'lstForMapInner >>> ' + lstForMapInner);
                    }

                    setsections.add(str.rlLabel);
                }

                //System.debug(LoggingLevel.INFO, 'outer size : ' + mapRlOuter.size());
                //System.debug(LoggingLevel.INFO, 'Internal Store size : ' + mapInternalStore.size());
                //System.debug(LoggingLevel.INFO, 'mapKey: ' + mapKey);
                //System.debug(LoggingLevel.INFO, 'lstForMapInner: ' + lstForMapInner);


            }

            if (mapRlOuter.size() > mapInternalStore.size()){
            mapInternalStore.put(mapKey, lstForMapInner);
            }
            //Call Method to fill MapInner
            //System.debug(LoggingLevel.INFO, 'mapInternalStore >>> ' + mapInternalStore);

            mapRlInner = new Map<Integer, List<SObject>>();
            mapRlFields = new Map<Integer, List<String>>();
            //mapRlLabels = new Map<Integer, List<String>>();
            mapRlLabels = new Map<String, String>();
            List<String> lstFields = new List<String>();
            List<String> lstLabels = new List<String>();

            String rightApi='',fldApi='';
            mapKey =1;
            List<SObject> lstToMap;

            schemaMap = Schema.getGlobalDescribe();


            for(Integer i : mapInternalStore.KeySet()){
                String buildStr = '', queryObj='',keyField='', buildLabels='', childName='';
                lstToMap = new List<SObject>();
                List<RLInternalDataWrapper> lstTemp = mapInternalStore.get(i);

                for(RLInternalDataWrapper rls: lstTemp){

                    //System.debug(LoggingLevel.INFO, 'rls.rlColfieldApi>>>' + rls.rlColfieldApi);
                    if (rls.rlColfieldApi == 'CreatedBy')
                    rightApi = 'CreatedBy.Name';
                    else if(rls.rlColfieldApi == 'LastModifiedBy')
                    rightApi = 'LastModifiedBy.Name';
                    /*else if(rls.rlColfieldApi.endsWith('__c')){
                    rightApi = rls.rlColfieldApi.substring(0, rls.rlColfieldApi.indexOf('__c',0));
                            rightApi = rightApi + '__r';
                            rightApi = rightApi + '.Name';
                    }*/
                    else if(rls.rlColfieldApi.endsWith(')')){
                    rightApi = rls.rlColfieldApi.replace(')', '');
                    rightApi = rightApi.replace('toLabel(', '');
                    }
                    else
                    rightApi = rls.rlColfieldApi;

                    buildStr = buildStr + rightApi + ',';
                    queryObj = rls.rlSobject;
                    childName = rls.rlChildName;
                    keyField = rls.rlKeyfield;

                    //buildLabels = buildLabels + ',';
                    mapRlLabels.put(rightApi,rls.rlColfieldLabel);
                }
                /*if (queryObj != 'OpenActivity' && queryObj != 'ActivityHistory' 
                && queryObj != 'CombinedAttachment' && queryObj != 'ProcessInstanceHistory'
                && queryObj != 'CaseArticle' && queryObj != 'AttachedContentNote' 
                && queryObj != 'AttachedContentDocument'){
                */
                if (queryObj != 'CaseArticle' && queryObj != 'EmailMessage'
                && queryObj != 'ActivityHistory' && queryObj != 'CaseHistory'
                && queryObj != 'AttachedContentDocument'){
                    if (buildStr.endsWith(','))
                    buildStr.substring(0, buildStr.length() - 1);

                    //if (buildLabels.endsWith(','))
                    //buildLabels.substring(0, buildLabels.length() - 1);

                    lstFields = buildStr.split(',');
                    //lstLabels = buildLabels.split(',');

                    lstToMap = setRLFieldValues(buildStr, queryObj, childName, keyField);

                    mapRlInner.put(mapKey, lstToMap);
                    //mapRlLabels.put(mapKey,lstLabels);
                    mapRlFields.put(mapKey, lstFields);

                    mapKey++;
                }
            }
            //System.debug(LoggingLevel.INFO, 'mapRlInner >>> ' + mapRlInner);

        }




    public void fillMapInner(List<layoutSectionsWrapper> lstSections){
        setsections.clear();
        //Map<Integer, List<DataWrapper>> mapInnerInner = new Map<Integer, List<DataWrapper>>();
        mapInner = new Map<Integer, List<DataWrapper>>();
        List<DataWrapper> lstForMapInner=new List<DataWrapper>();
        List<DataWrapper> lstData;
        Integer key=1;

        for(layoutSectionsWrapper item: lstSections){
             if (item.fieldtype != 'VisualforcePage'){
                //System.debug(LoggingLevel.INFO, item.cols + '--' + item.sectionName + '--' + item.fieldLabel + '--' + item.fieldtype + '--' + item.fieldAPI);
                if(setsections.contains(item.sectionName)){//Existing Section
                    if(item.fieldType=='field'){
                    lstData = new List<DataWrapper>();
                    lstData.add(new DataWrapper(item.fieldLabel,item.fieldAPI,item.fieldType));
                    lstForMapInner.addAll(lstData);
                    }
                }
                else{//New Section
                    lstData = new List<DataWrapper>();
                    if(key==1 && lstForMapInner.size()>0){

                        mapInner.put(key, lstForMapInner);
                        key++;
                    }
                    else{
                        if(key!=1 && !mapInner.containsKey(key)){
                            mapInner.put(key, lstForMapInner);
                            key++;
                        }
                    }
                    if(item.fieldType=='field'){
                        lstForMapInner = new List<DataWrapper>();
                        lstData.add(new DataWrapper(item.fieldLabel,item.fieldAPI,item.fieldType));
                        lstForMapInner.addAll(lstData);
                    }
                }
                setsections.add(item.sectionName);
            }
        }
        if(mapOuter.size() > mapInner.size()){
        mapInner.put(key, lstForMapInner);
        }
        //for(Integer i:mapInner.KeySet()){
        //List<DataWrapper> lstTemp = mapInner.get(i);
        //System.debug(LoggingLevel.INFO, 'mapInner List>>>' + i + ' ' + lstTemp.size());
        //System.debug(LoggingLevel.INFO, 'List Inside' + i + ' ' + lstTemp);
        //}

    }


    public List<SObject> setRLFieldValues(String fieldsTobeQueried, String rlSobjet, String childName, String whereField){
        String query=''; //List<String> lstFields=new List<String>();
        //List<SObject> lstSobj = new List<SObject>();
        List<WrapperRecord> lstWrapRec = new List<WrapperRecord>();
        if(fieldsTobeQueried != null && fieldsTobeQueried.endsWith(','))
        fieldsTobeQueried = fieldsTobeQueried.substring(0, fieldsTobeQueried.length() - 1);

        //Type customType = Type.forName('WrapperRecord');
        //WrapperRecord instance = (WrapperRecord)customType.newInstance();

        //query = 'select ' + fieldsTobeQueried + ' from ' + rlSobjet + ' where ' + whereField + '= \''+paramId+'\'';
        //System.debug(LoggingLevel.INFO, query);
        //List<SObject> lstSobj = (List<SObject>)database.query(query);

        //query = 'select Id, (select ' + fieldsTobeQueried + ' from ' + childName + ') from Case where Id' + '= \''+paramId+'\'';
        query = 'select Id, (select ' + fieldsTobeQueried + ' from ' + childName + ') from ' +  sobjectName + ' where Id' + '= \''+paramId+'\'';
        //List<Case> lstcase = database.query(query);
        System.debug(LoggingLevel.INFO, query);
        List<SObject> lstCase = database.query(query);//future use
        //System.debug(LoggingLevel.INFO, 'case child: ' + lstcase.get(0).getSObjects(childName));
        List<SObject> lstSobj = lstcase.get(0).getSObjects(childName);
        if (lstSobj == null)
        lstSobj= new List<SObject>();

        /*for(SObject obj: lstSobj){

        System.debug(LoggingLevel.INFO, 'obj >>> ' + obj.get('Subject'));

        }*/
        //lstFields = (List<String>)fieldsTobeQueried;
        return lstSobj;

    }



    //public Case putFieldApiWithReference(List<layoutSectionsWrapper> lstSections, String sobj){
       public SObject putFieldApiWithReference(List<layoutSectionsWrapper> lstSections, String sobj){
        String buildStr='', soql='';
        //Case c=new Case();
        //SObject obj = new SObject();

        //Remove Duplicate Api Names -- 
        //In this case, createddate is same for Date/Time Opened & Created Date fields.
        String fld;
        for(layoutSectionsWrapper item: lstSections){
            if (item.fieldType=='field'){
                fld='';
                                //System.debug(LoggingLevel.INFO, 'fieldMap>>>> ' + fieldMap);
                                System.debug(LoggingLevel.INFO, 'item.fieldAPI>>>> ' + item.fieldAPI);
                Schema.DisplayType fielddataType = fieldMap.get(item.fieldAPI).getDescribe().getType();
                System.debug(LoggingLevel.INFO, 'fielddataType>>>> ' + String.valueOf(fielddataType));
                if (String.valueOf(fielddataType) == 'reference'){

                    fld = item.fieldAPI;
                    if (fld.endsWith('Id') && fld!='ParentId'){
                        fld = fld.substring(0, fld.indexOf('Id',0));
                        buildStr = buildStr + fld + '.Name,'; 
                    }
                    if(fld.endsWith('__c')){
                        fld = fld.substring(0, fld.indexOf('__c',0));
                        fld = fld + '__r';
                        buildStr = buildStr + fld + '.Name,'; 
                    }
                    if (fld == 'ParentId'){
                    fld = fld.substring(0, fld.indexOf('Id',0));
                    if (sObj == 'Case')
                    buildStr = buildStr + fld + '.CaseNumber,'; 
                    else
                    buildStr = buildStr + fld + '.Name,'; 
                    }

                }
                else{ 
                    String[] temp = buildStr.split(',');
                    boolean x=false;
                    for(String t: temp){
                        if (t == item.fieldAPI){
                            x=true;
                            break;
                        }
                    }
                 //if(!buildStr.contains(item.fieldAPI)) //Remove Duplicate Api Names -- 
                	if (!x)
                       buildStr = buildStr + item.fieldAPI + ',';  
                
                }
            
                System.debug(LoggingLevel.info, 'buildStr>>> ' + buildStr);
            }
        }
        //System.debug(LoggingLevel.INFO, buildStr.substring(0, buildStr.length() - 1));

        if(buildStr != null && buildStr.endsWith(','))
        buildStr = buildStr.substring(0, buildStr.length() - 1);

        //System.debug(LoggingLevel.INFO, buildStr);

        //if (sobj == 'Case'){
        soql = 'select ' + buildStr + ' from ' + sobj + ' where Id = \''+paramId+'\'';
        System.debug(LoggingLevel.INFO, 'soql inside putFieldApiWithReference:' + soql);
        //c = Database.query(soql);
        SObject obj = Database.query(soql);
        //}

        return obj;
    }

    //***************************** Exist in CSCommScopeUtil
    public static String buildQueryFields(Schema.DescribeSObjectResult sdo) {

            Map<String, Schema.SObjectField> objectFields_map = getFieldDescribe(sdo);
            String queryFields = '';
            Boolean firstFlag = true;
            for (string c : objectFields_map.keySet()) {
                if (!firstFlag) {
                    queryFields = queryFields + ', ';
                }
                queryFields = queryFields + c;
                firstFlag = false;
            }
            return queryFields;
        }

        //Exist in CSCommScopeUtil
         public static String buildQuery(Schema.DescribeSObjectResult sdo) {
            String queryFields = buildQueryFields(sdo);
            queryFields = 'SELECT ' + queryFields + ' FROM ' + sdo.getName() + ' ';
            return queryFields;
        }

        //Exist in CSCommScopeUtil
        public static Map<String, Schema.SObjectField> getFieldDescribe(Schema.DescribeSObjectResult sdo) {
            if (!fieldDescribeCache.containsKey(sdo.getName())) {
                fieldDescribeCache.put(sdo.getName(), sdo.fields.getMap());
            }
            return fieldDescribeCache.get(sdo.getName());
        }

        //Layout Section Wrapper Classes
    public class layoutSectionsWrapper{
        public String cols{get;set;}
        public String sectionName{get;set;}
        public String fieldLabel{get;set;}
        public String fieldtype{get;set;}
        public String fieldAPI{get;set;}

        public layoutSectionsWrapper(){
            cols = this.cols;
            sectionName = this.sectionName;
            fieldLabel = this.fieldLabel;
            fieldtype = this.fieldtype;
            fieldAPI = this.fieldAPI;
        }
    }

    //Section Header and Number of cols per sections
    public class HeaderWrapper{
        public String header{get;set;}
        public Integer numCols{get;set;}

        public HeaderWrapper(String header,Integer numCols){
            this.header=header;
            this.numCols=numCols;
        }
    }

    //Layout Sections Data
    public class DataWrapper{
        public String fieldLabel{get;set;}
        public String fieldApi{get;set;}
        public String fieldType{get;set;}

        public DataWrapper(String fieldLabel, String fieldApi, String fieldType){
            this.fieldLabel = fieldLabel;
            this.fieldApi = fieldApi;
            this.fieldType = fieldType;
        }
    }

    //Related List Wrapper Classes
    public class layoutRelatedWrapper{
        public String  rlLabel{get;set;}
        public String rlSobject{get;set;}
        public String rlChildName{get;set;} 
        public String rlKeyfield{get;set;}
        public String rlColfieldLabel{get;set;}
        public String rlColfieldApi{get;set;}

        public layoutRelatedWrapper(){
            this.rlLabel = rlLabel;
            this.rlSobject = rlSobject;
            this.rlChildName = rlChildName;
            this.rlKeyfield = rlKeyfield;
            this.rlColfieldLabel = rlColfieldLabel;
            this.rlColfieldApi = rlColfieldApi;
        }
    }

    //Internal Map
    public class RLInternalDataWrapper{
        public String  rlLabel{get;set;}
        public String rlSobject{get;set;}
        public String rlChildName{get;set;} 
        public String rlKeyfield{get;set;}
        public String rlColfieldLabel{get;set;}
        public String rlColfieldApi{get;set;}

        public RLInternalDataWrapper(String rlLabel, String rlSobject, String rlChildName, String rlKeyfield, String rlColfieldLabel, String rlColfieldApi){
            this.rlLabel = rlLabel;
            this.rlSobject = rlSobject;
            this.rlChildName = rlChildName;
            this.rlKeyfield = rlKeyfield;
            this.rlColfieldLabel = rlColfieldLabel;
            this.rlColfieldApi = rlColfieldApi;
        }
    }

    //Related List Data Wrapper
    public class WrapperRecord{
        public List<RlDataWrapper> lstdataWrapper{get;set;}
        //public Integer size{get;set;}
        //public Integer numRecords{get;set;}

        //public WrapperRecord(List<RlDataWrapper> lst, Integer size, Integer numRecords){
        public WrapperRecord(List<RlDataWrapper> lst){
            this.lstdataWrapper = lst;
            //this.size = size;
            //this.numRecords = numRecords;
        }
    }

    //Related List Data
    public class RlDataWrapper{
        public String fieldLabel{get;set;}
        public String fieldValue{get;set;}

        public RlDataWrapper(String fieldLabel, String fieldValue){
            this.fieldLabel = fieldLabel;
            this.fieldValue = fieldValue;
        }
    }
    
}