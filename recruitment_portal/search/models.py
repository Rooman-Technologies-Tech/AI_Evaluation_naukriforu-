import uuid
import json
from datetime import datetime
from django.conf import settings
from django.utils import timezone
import boto3
from botocore.exceptions import ClientError


class DynamoDBManager:
    """Manager for DynamoDB operations."""
    
    def __init__(self, table_name):
        self.table_name = table_name
        self.dynamodb = boto3.resource('dynamodb', region_name=settings.AWS_REGION)
        self.table = self.dynamodb.Table(table_name)
    
    def put_item(self, item):
        """Put an item in DynamoDB."""
        try:
            response = self.table.put_item(Item=item)
            return response
        except ClientError as e:
            print(f"Error putting item in DynamoDB: {e}")
            return None
    
    def get_item(self, key):
        """Get an item from DynamoDB."""
        try:
            response = self.table.get_item(Key=key)
            return response.get('Item')
        except ClientError as e:
            print(f"Error getting item from DynamoDB: {e}")
            return None
    
    def query(self, key_condition_expression, **kwargs):
        """Query items from DynamoDB."""
        try:
            response = self.table.query(
                KeyConditionExpression=key_condition_expression,
                **kwargs
            )
            return response.get('Items', [])
        except ClientError as e:
            print(f"Error querying DynamoDB: {e}")
            return []
    
    def scan(self, **kwargs):
        """Scan items from DynamoDB."""
        try:
            response = self.table.scan(**kwargs)
            return response.get('Items', [])
        except ClientError as e:
            print(f"Error scanning DynamoDB: {e}")
            return []


class SearchIndex:
    """Model for storing search indexes in DynamoDB."""
    
    def __init__(self):
        self.table_name = f"{settings.ENVIRONMENT}-search-indexes"
        self.db_manager = DynamoDBManager(self.table_name)
    
    def create_search_index(self, candidate_id, search_type, embeddings, metadata=None):
        """Create a search index for a candidate."""
        item = {
            'id': str(uuid.uuid4()),
            'candidate_id': candidate_id,
            'search_type': search_type,
            'embeddings': embeddings,
            'metadata': metadata or {},
            'created_at': datetime.utcnow().isoformat(),
            'updated_at': datetime.utcnow().isoformat()
        }
        
        return self.db_manager.put_item(item)
    
    def get_candidate_indexes(self, candidate_id, search_type=None):
        """Get all search indexes for a candidate."""
        key_condition = 'candidate_id = :candidate_id'
        expression_values = {':candidate_id': candidate_id}
        
        if search_type:
            key_condition += ' AND search_type = :search_type'
            expression_values[':search_type'] = search_type
        
        return self.db_manager.query(
            'candidate_id = :candidate_id',
            ExpressionAttributeValues=expression_values,
            IndexName='CandidateSearchIndex'
        )
    
    def update_search_index(self, index_id, embeddings, metadata=None):
        """Update an existing search index."""
        item = self.db_manager.get_item({'id': index_id})
        if item:
            item['embeddings'] = embeddings
            if metadata:
                item['metadata'].update(metadata)
            item['updated_at'] = datetime.utcnow().isoformat()
            return self.db_manager.put_item(item)
        return None
    
    def delete_search_index(self, index_id):
        """Delete a search index."""
        try:
            self.db_manager.table.delete_item(Key={'id': index_id})
            return True
        except ClientError as e:
            print(f"Error deleting search index: {e}")
            return False


class AnalyticsData:
    """Model for storing analytics data in DynamoDB."""
    
    def __init__(self):
        self.table_name = f"{settings.ENVIRONMENT}-analytics"
        self.db_manager = DynamoDBManager(self.table_name)
    
    def record_search_analytics(self, search_query, results_count, search_duration, user_id=None):
        """Record search analytics."""
        item = {
            'id': str(uuid.uuid4()),
            'date': datetime.utcnow().strftime('%Y-%m-%d'),
            'metric_type': 'search',
            'search_query': search_query,
            'results_count': results_count,
            'search_duration': search_duration,
            'user_id': user_id,
            'timestamp': datetime.utcnow().isoformat()
        }
        
        return self.db_manager.put_item(item)
    
    def record_candidate_view(self, candidate_id, user_id=None):
        """Record candidate profile view."""
        item = {
            'id': str(uuid.uuid4()),
            'date': datetime.utcnow().strftime('%Y-%m-%d'),
            'metric_type': 'candidate_view',
            'candidate_id': candidate_id,
            'user_id': user_id,
            'timestamp': datetime.utcnow().isoformat()
        }
        
        return self.db_manager.put_item(item)
    
    def record_job_view(self, job_id, user_id=None):
        """Record job description view."""
        item = {
            'id': str(uuid.uuid4()),
            'date': datetime.utcnow().strftime('%Y-%m-%d'),
            'metric_type': 'job_view',
            'job_id': job_id,
            'user_id': user_id,
            'timestamp': datetime.utcnow().isoformat()
        }
        
        return self.db_manager.put_item(item)
    
    def get_daily_metrics(self, date, metric_type=None):
        """Get daily metrics for a specific date."""
        key_condition = 'date = :date'
        expression_values = {':date': date}
        
        if metric_type:
            key_condition += ' AND metric_type = :metric_type'
            expression_values[':metric_type'] = metric_type
        
        return self.db_manager.query(
            key_condition,
            ExpressionAttributeValues=expression_values,
            IndexName='DateMetricIndex'
        )
    
    def get_search_analytics(self, start_date=None, end_date=None):
        """Get search analytics for a date range."""
        if not start_date:
            start_date = datetime.utcnow().strftime('%Y-%m-%d')
        if not end_date:
            end_date = start_date
        
        items = []
        current_date = datetime.strptime(start_date, '%Y-%m-%d')
        end_date_obj = datetime.strptime(end_date, '%Y-%m-%d')
        
        while current_date <= end_date_obj:
            date_str = current_date.strftime('%Y-%m-%d')
            daily_items = self.get_daily_metrics(date_str, 'search')
            items.extend(daily_items)
            current_date = current_date.replace(day=current_date.day + 1)
        
        return items


class CachedResults:
    """Model for storing cached AI search results in DynamoDB."""
    
    def __init__(self):
        self.table_name = f"{settings.ENVIRONMENT}-cached-results"
        self.db_manager = DynamoDBManager(self.table_name)
    
    def cache_search_results(self, query_hash, results, ttl_hours=24):
        """Cache search results."""
        ttl_timestamp = int((datetime.utcnow().timestamp() + (ttl_hours * 3600)))
        
        item = {
            'id': query_hash,
            'results': results,
            'created_at': datetime.utcnow().isoformat(),
            'ttl': ttl_timestamp
        }
        
        return self.db_manager.put_item(item)
    
    def get_cached_results(self, query_hash):
        """Get cached search results."""
        item = self.db_manager.get_item({'id': query_hash})
        if item:
            # Check if TTL has expired
            current_timestamp = int(datetime.utcnow().timestamp())
            if item.get('ttl', 0) > current_timestamp:
                return item.get('results')
            else:
                # Remove expired item
                self.delete_cached_results(query_hash)
        return None
    
    def delete_cached_results(self, query_hash):
        """Delete cached results."""
        try:
            self.db_manager.table.delete_item(Key={'id': query_hash})
            return True
        except ClientError as e:
            print(f"Error deleting cached results: {e}")
            return False


# Utility functions for working with DynamoDB
def get_search_index_manager():
    """Get search index manager instance."""
    return SearchIndex()


def get_analytics_manager():
    """Get analytics manager instance."""
    return AnalyticsData()


def get_cached_results_manager():
    """Get cached results manager instance."""
    return CachedResults()


def hash_query(query, filters=None):
    """Create a hash for a search query."""
    import hashlib
    query_string = query
    if filters:
        query_string += json.dumps(filters, sort_keys=True)
    return hashlib.md5(query_string.encode()).hexdigest() 