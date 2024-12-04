public with sharing class accountKnowledgeArticleSearchController {

    /**
     * Fetch Account Name based on Account ID
     */
    @AuraEnabled(cacheable=true)
    public static String getAccountName(Id accountId) {
        if (String.isBlank(accountId)) {
            throw new AuraHandledException('Account ID is required.');
        }
        try {
            Account account = [SELECT Name FROM Account WHERE Id = :accountId];
            return account.Name;
        } catch (Exception ex) {
            System.debug('Error: ' + ex.getMessage());
            throw new AuraHandledException('Error fetching Account Name: ' + ex.getMessage());
        }
    }

    /**
     * Search for Knowledge Articles based on Account Name and Search Term
     */
    @AuraEnabled(cacheable=true)
    public static List<Knowledge__kav> searchKnowledgeArticles(Id accountId, String searchTerm) {
        if (String.isBlank(accountId) || String.isBlank(searchTerm)) {
            return new List<Knowledge__kav>();
        }

        try {
            // Get the Account Name
            Account account = [SELECT Name FROM Account WHERE Id = :accountId];
            String accountName = account.Name;

            // SOSL Query to search Knowledge Articles
            String searchQuery = 'FIND \'' + String.escapeSingleQuotes(searchTerm) + '*\' IN ALL FIELDS ' +
                'RETURNING Knowledge__kav(Id, Title, Article_Body__c ' +
                'WHERE PublishStatus = \'Online\' AND Language = \'en_US\' AND Title LIKE \'%' + String.escapeSingleQuotes(accountName) + '%\')';

            System.debug('Search Query: ' + searchQuery);

            // Execute the query
            List<List<sObject>> searchResults = Search.query(searchQuery);
            List<Knowledge__kav> articles = (List<Knowledge__kav>) searchResults[0];

            // Sort the articles alphabetically by Title (case-insensitive)
            articles.sort(new KnowledgeArticleComparator());

            return articles;
        } catch (Exception ex) {
            System.debug('Error: ' + ex.getMessage());
            throw new AuraHandledException('Error fetching knowledge articles: ' + ex.getMessage());
        }
    }

    /**
     * Comparator class to sort Knowledge Articles by Title (case-insensitive)
     */
    public class KnowledgeArticleComparator implements Comparator<Knowledge__kav> {
        public Integer compare(Knowledge__kav a, Knowledge__kav b) {
            String titleA = a.Title != null ? a.Title.toLowerCase() : '';
            String titleB = b.Title != null ? b.Title.toLowerCase() : '';
            return titleA.compareTo(titleB);
        }
    }
}