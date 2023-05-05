global class BatchPapercutIngestion implements Database.Batchable<SObject>, Schedulable {
    
    public static Integer maxBatchSize = 1;
    Boolean forceLog = False;
    public BatchPapercutIngestion() {}

    //required to force log for testing
    public BatchPapercutIngestion(Boolean b) {
        this.forceLog = b;
    }

    global void execute(SchedulableContext ctx) {
        Database.executeBatch(new BatchPapercutIngestion(), BatchPapercutIngestion.maxBatchSize);
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = PaperCutService.getCaseQuery();
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Case> caseList) {

        try {
            if (this.forceLog) {
                //this code throws an error
                System.debug('execute inside try if: ' + this.forceLog);
                Double d = 1.0 / 0;
            }
            System.debug('execute inside try: ' + caseList);
            PaperCutService.ingest(caseList);
        }
        catch (Exception e) {
            System.debug('execute inside catch: ' + e);
            //https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_exception_methods.htm
            WLF_Log__c log = new WLF_Log__c (
                Apex_Class__c = BatchPapercutIngestion.class.getName()
                , Exception_Type__c = e.getTypeName()
                , Line_Number__c = e.getLineNumber()
                , Failed_On__c = 'Papercut ingestion of Cases'
                , Created_Datetime__c = System.Now()
            );
            String message = e.getMessage();
            if (message != null) {
                log.Error_Message__c = message.substring(0, Math.Min(255, message.length()));
            }
            String stackTrace = e.getStackTraceString();
            if (stackTrace != null) {
                log.Stack_Trace__c = stackTrace.substring(0, Math.Min(32768, stackTrace.length()));
            }
            insert log;
        }
    }

    global void finish(Database.BatchableContext BC) {}
}