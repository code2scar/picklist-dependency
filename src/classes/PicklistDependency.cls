/**
 * @author: Carlos Aguiar - @code2scar
 * @see: https://code2scar.gitbook.io/code-solutions-for-salesforce/obtenha-valores-dependentes-de-picklist-via-campo-controlador
 * @see: https://developer.salesforce.com/docs/atlas.en-us.uiapi.meta/uiapi/ui_api_features_records_dependent_picklist.htm
 * @see: https://glyntalkssalesforce.blogspot.com/2018/08/dependent-picklist-values-in-apex.html
 */
public class PicklistDependency {

    final static Integer BIT_SIZE_FOR_BASE64 = 6;
    final static Integer MAX_BIT_INDEX_FOR_BASE64 = 5;
    final static String BASE64_MAPPING = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    Integer maxLoopCounter;
    Schema.sObjectField fieldController;
    Schema.DescribeFieldResult fieldControllerResult;
    List<Schema.PicklistEntry> controllerEntries;
    List<Schema.PicklistEntry> dependencyEntries;

    public List<String> getDependentValuesByMaster(String sObjectName, String dependentFieldName, String masterValue) {
        this.setup(sObjectName, dependentFieldName);
        List<String> dependentValuesByMaster = new List<String>();
        if (fieldController == null) {
            return null;
        }
        for (Schema.PicklistEntry dependencyEntry : dependencyEntries) {
            List<String> charsOfValidForProperty = getCharsOfValidForProperty(dependencyEntry);
            if (Lists.isEmpty(charsOfValidForProperty)) {
                continue;
            }
            for (Integer controllerEntryPosition = 0; controllerEntryPosition < maxLoopCounter; controllerEntryPosition++) {
                String controllerValue = getValueOfFieldController(controllerEntries, controllerEntryPosition);
                if (String.isBlank(controllerValue)) {
                    continue;
                }
                Integer bitIndex = controllerEntryPosition / BIT_SIZE_FOR_BASE64;
                if (bitIndex > charsOfValidForProperty.size() - 1) {
                    break;
                }
                Integer sizeOfBitShift = MAX_BIT_INDEX_FOR_BASE64 - Math.mod(controllerEntryPosition, BIT_SIZE_FOR_BASE64);
                Integer targetCharIndex = BASE64_MAPPING.indexOf(charsOfValidForProperty.get(bitIndex));
                if ((targetCharIndex & (1 << sizeOfBitShift)) == 0) {
                    continue;
                }
                if (controllerValue != masterValue) {
                    continue;
                }
                dependentValuesByMaster.add(dependencyEntry.getLabel());
            }
        }
        return dependentValuesByMaster;
    }

    public Map<String, List<String>> getAllDependentValuesByController(String sObjectName, String dependentFieldName) {
        this.setup(sObjectName, dependentFieldName);
        Map<String, List<String>> allDependentValuesByController = new Map<String, List<String>>();
        if (fieldController == null) {
            return null;
        }
        for (Schema.PicklistEntry dependencyEntry : dependencyEntries) {
            List<String> charsOfValidForProperty = getCharsOfValidForProperty(dependencyEntry);
            if (Lists.isEmpty(charsOfValidForProperty)) {
                continue;
            }
            for (Integer controllerEntryPosition = 0; controllerEntryPosition < maxLoopCounter; controllerEntryPosition++) {
                String controllerValue = getValueOfFieldController(controllerEntries, controllerEntryPosition);
                if (String.isBlank(controllerValue)) {
                    continue;
                }
                Integer bitIndex = controllerEntryPosition / BIT_SIZE_FOR_BASE64;
                if (bitIndex > charsOfValidForProperty.size() - 1) {
                    break;
                }
                Integer sizeOfBitShift = MAX_BIT_INDEX_FOR_BASE64 - Math.mod(controllerEntryPosition, BIT_SIZE_FOR_BASE64);
                Integer targetCharIndex = BASE64_MAPPING.indexOf(charsOfValidForProperty.get(bitIndex));
                if ((targetCharIndex & (1 << sizeOfBitShift)) == 0) {
                    continue;
                }
                if (!allDependentValuesByController.containsKey(controllerValue)) {
                    allDependentValuesByController.put(controllerValue, new List<String>());
                }
                allDependentValuesByController.get(controllerValue).add(dependencyEntry.getLabel());
            }
        }
        return allDependentValuesByController;
    }

    @TestVisible
    private void setup(String sObjectName, String dependentFieldName) {
        Schema.DescribeFieldResult fieldDependencyResult = getFieldDependencyResult(sObjectName, dependentFieldName);
        this.fieldController = fieldDependencyResult.getController();
        if (this.fieldController == null) {
            return;
        }
        this.fieldControllerResult = fieldController.getDescribe();
        this.controllerEntries = getFieldControllerEntries(fieldControllerResult);
        this.dependencyEntries = getActiveDependentFieldEntries(fieldDependencyResult);
        this.maxLoopCounter = controllerEntries != null ? controllerEntries.size() : 2;
    }

    @TestVisible
    private Schema.DescribeFieldResult getFieldDependencyResult(String sObjectName, String dependentFieldName) {
        return Schema.getGlobalDescribe()
            .get(sObjectName)
            .getDescribe().fields.getMap()
            .get(dependentFieldName)
            .getDescribe();
    }

    @TestVisible
    private List<Schema.PicklistEntry> getFieldControllerEntries(Schema.DescribeFieldResult fieldControllerResult) {
        if (fieldControllerResult.getType() == Schema.DisplayType.Boolean) {
            return null;
        }
        return fieldControllerResult.getPicklistValues();
    }

    @TestVisible
    private List<Schema.PicklistEntry> getActiveDependentFieldEntries(Schema.DescribeFieldResult fieldDependencyResult) {
        List<Schema.PicklistEntry> activeEntries = new List<Schema.PicklistEntry>();
        for (Schema.PicklistEntry currentEntry : fieldDependencyResult.getPicklistValues()) {
            if (currentEntry.isActive()) {
                activeEntries.add(currentEntry);
            }
        }
        return activeEntries;
    }

    @TestVisible
    private List<String> getCharsOfValidForProperty(Schema.PicklistEntry dependencyEntry) {
        String validFor = JSON.serialize(dependencyEntry)
            .substringAfter('"validFor":"')
            .substringBefore('"');
        return String.isBlank(validFor) ? null : validFor.split('');
    }

    @TestVisible
    private String getValueOfFieldController(List<Schema.PicklistEntry> controllerEntries, Integer currentIndex) {
        if (controllerEntries == null) {
            return String.valueOf(currentIndex == 1);
        }
        else if (controllerEntries.get(currentIndex).isActive()) {
            return controllerEntries.get(currentIndex).getLabel();
        }
        else {
            return null;
        }
    }

}