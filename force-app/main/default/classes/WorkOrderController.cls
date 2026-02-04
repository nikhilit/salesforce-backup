// WorkOrderController.cls
public with sharing class WorkOrderController {
  
  @AuraEnabled(cacheable=false)
  public static Map<String, Object> getWorkOrdersByMetadata(
    String listViewName,
    String userId,
    String profileName,
    String roleName
  ) {
    try {
      // Get metadata configuration - UPDATE THIS WITH YOUR ACTUAL METADATA TYPE NAME
      List<Work_Order_Dynamic_List_Views__mdt> config = [
        SELECT Id, DeveloperName, Label, SOQL_Query__c, 
               Filter_By_Owner__c, Filter_By_Status__c, 
               Status_Values__c, Record_Limit__c,
               Applicable_Profiles__c, Applicable_Roles__c
        FROM Work_Order_Dynamic_List_Views__mdt
        WHERE DeveloperName = :listViewName
        LIMIT 1
      ];

      if (config.isEmpty()) {
        return new Map<String, Object>{
          'success' => false,
          'message' => 'List view configuration not found: ' + listViewName
        };
      }

      Work_Order_Dynamic_List_Views__mdt metadata = config[0];

      // Check if current user has access to this list view
      if (!hasAccessToListView(metadata, profileName, roleName)) {
        return new Map<String, Object>{
          'success' => false,
          'message' => 'You do not have access to this list view'
        };
      }

      // Build dynamic SOQL query
      String soqlQuery = buildSOQLQuery(metadata, userId);

      // Execute query
      List<WorkOrder> records = Database.query(soqlQuery);

      // Get column metadata
      List<Map<String, Object>> columns = getColumnMetadata(listViewName);

      return new Map<String, Object>{
        'success' => true,
        'data' => records,
        'columns' => columns
      };

    } catch (Exception e) {
      return new Map<String, Object>{
        'success' => false,
        'message' => 'Error: ' + e.getMessage()
      };
    }
  }

  private static String buildSOQLQuery(
    Work_Order_Dynamic_List_Views__mdt metadata,
    String userId
  ) {
    String query = metadata.SOQL_Query__c;

    // Replace dynamic placeholders
    query = query.replace('{UserId}', '\'' + userId + '\'');
    query = query.replace('{TODAY}', String.valueOf(Date.today()));

    // Add filter for owner if applicable
    if (metadata.Filter_By_Owner__c) {
      if (!query.toUpperCase().contains('WHERE')) {
        query += ' WHERE OwnerId = \'' + userId + '\'';
      } else {
        query += ' AND OwnerId = \'' + userId + '\'';
      }
    }

    // Add filter for status if applicable
    if (metadata.Filter_By_Status__c && String.isNotBlank(metadata.Status_Values__c)) {
      String statusValues = metadata.Status_Values__c;
      List<String> statuses = statusValues.split(',');
      String statusFilter = '(';
      for (Integer i = 0; i < statuses.size(); i++) {
        statusFilter += '\'' + statuses[i].trim() + '\'';
        if (i < statuses.size() - 1) {
          statusFilter += ',';
        }
      }
      statusFilter += ')';

      if (!query.toUpperCase().contains('WHERE')) {
        query += ' WHERE Status IN ' + statusFilter;
      } else {
        query += ' AND Status IN ' + statusFilter;
      }
    }

    // Add order by and limit
    if (!query.toUpperCase().contains('ORDER BY')) {
      query += ' ORDER BY CreatedDate DESC';
    }

    Integer recordLimit = (Integer) metadata.Record_Limit__c;
    if (recordLimit > 0) {
      query += ' LIMIT ' + recordLimit;
    } else {
      query += ' LIMIT 10000';
    }

    System.debug('Final SOQL Query: ' + query);
    return query;
  }

  private static Boolean hasAccessToListView(
    Work_Order_Dynamic_List_Views__mdt metadata,
    String profileName,
    String roleName
  ) {
    // If no restrictions, allow access
    if (String.isBlank(metadata.Applicable_Profiles__c) && 
        String.isBlank(metadata.Applicable_Roles__c)) {
      return true;
    }

    Boolean hasProfileAccess = String.isBlank(metadata.Applicable_Profiles__c) ||
      metadata.Applicable_Profiles__c.contains(profileName);
    
    Boolean hasRoleAccess = String.isBlank(metadata.Applicable_Roles__c) ||
      metadata.Applicable_Roles__c.contains(roleName);

    return hasProfileAccess && hasRoleAccess;
  }

  private static List<Map<String, Object>> getColumnMetadata(String listViewName) {
    List<Map<String, Object>> columns = new List<Map<String, Object>>();

    try {
      // Query related column metadata
      List<WO_List_View_Columns__mdt> columnConfigs = [
        SELECT DeveloperName, Field_Name__c, Label__c, 
               Data_Type__c, Is_Sortable__c, Width__c
        FROM WO_List_View_Columns__mdt
        WHERE List_View__r.DeveloperName = :listViewName
        ORDER BY Order__c ASC
      ];

      for (WO_List_View_Columns__mdt col : columnConfigs) {
        Map<String, Object> colMap = new Map<String, Object>{
          'label' => col.Label__c,
          'fieldName' => col.Field_Name__c,
          'type' => col.Data_Type__c,
          'sortable' => col.Is_Sortable__c
        };

        if (String.isNotBlank(col.Width__c)) {
          colMap.put('width', col.Width__c);
        }

        columns.add(colMap);
      }

      System.debug('Columns: ' + columns);
    } catch (Exception e) {
      System.debug('Error querying column metadata: ' + e.getMessage());
    }

    return columns;
  }

  @AuraEnabled(cacheable=true)
  public static Map<String, String> getUserInfo() {
    try {
      User currentUser = [
        SELECT Id, Username, ProfileId, UserRoleId
        FROM User
        WHERE Id = :UserInfo.getUserId()
        LIMIT 1
      ];

      // Get profile name
      Profile profileObj = [
        SELECT Name
        FROM Profile
        WHERE Id = :currentUser.ProfileId
        LIMIT 1
      ];

      // Get role name
      String roleName = '';
      if (currentUser.UserRoleId != null) {
        UserRole roleObj = [
          SELECT Name
          FROM UserRole
          WHERE Id = :currentUser.UserRoleId
          LIMIT 1
        ];
        roleName = roleObj.Name;
      }

      return new Map<String, String>{
        'Id' => currentUser.Id,
        'Username' => currentUser.Username,
        'ProfileName' => profileObj.Name,
        'RoleName' => roleName
      };
    } catch (Exception e) {
      System.debug('Error getting user info: ' + e.getMessage());
      return new Map<String, String>{
        'Id' => UserInfo.getUserId(),
        'Username' => '',
        'ProfileName' => '',
        'RoleName' => ''
      };
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<Map<String, Object>> getListViewColumns(String listViewName) {
    return getColumnMetadata(listViewName);
  }
}