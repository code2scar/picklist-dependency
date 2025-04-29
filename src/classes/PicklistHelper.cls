/**
 * @author: Carlos Aguiar - @code2scar
 */
public class PicklistHelper {

    static final PicklistDependency picklistDependency = new PicklistDependency();

    @AuraEnabled(cacheable = true)
    public static List<String> getDependentValuesByMaster(String sObjectName, String dependentFieldName, String masterValue) {
        return picklistDependency.getDependentValuesByMaster(sObjectName, dependentFieldName, masterValue);
    }

    @AuraEnabled(cacheable = true)
    public static Map<String, List<String>> getAllDependentValuesByController(String sObjectName, String dependentFieldName) {
        return picklistDependency.getAllDependentValuesByController(sObjectName, dependentFieldName);
    }

}