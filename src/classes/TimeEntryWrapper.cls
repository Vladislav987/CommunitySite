public with sharing class TimeEntryWrapper {

    private List<TimeEntry> time_entries;
    private Integer total_count;

    public List<TimeEntry> getTimeEntries() {
        return time_entries;
    }

    public Integer getTotalCount() {
        return total_count;
    }


    public class TimeEntry {

        private String Id;
        private Map<String, String> project;
        private Map<String, String> issue;
        private Map<String, String> user;
        private Map<String, String> activity;
        private Decimal hours;
        private String comments;
        private String spent_on;
        private String entity_id;
        private String entity_type;
        private String created_on;
        private String updated_on;


        public Decimal getProjectId() {
            return Decimal.valueOf(this.project.get('id'));
        }

        public Decimal getUserId() {
            return Decimal.valueOf(this.user.get('id'));
        }

        public Decimal getHours() {
            return this.hours;
        }
    }

}