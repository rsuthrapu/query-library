with
    CLOUD_DATA (col) as
      (
        select table_name  from cloud_cc_table_metadata UNION ALL
        select column_name  from cloud_cc_table_metadata UNION ALL
        select data_type  from cloud_cc_table_metadata
      ),
   ONPREM_DATA (col) as
     (
        select table_name  from onprem_cc_data_metadata UNION ALL
        select column_name  from onprem_cc_data_metadata UNION ALL
        select data_type  from onprem_cc_data_metadata       
     )
   select DISTINCT a.col as cloud, b.col as onprem,
     case when lower(a.col) = lower(b.col) then
               'exists in both' ||
               case when lower(a.col) = lower(b.col) then ' and exact match'
                    else 'but different'
               end
          when a.col is null then 'missing in cloud'
          when b.col is null then 'missing in onprem'
     end differences
   from CLOUD_DATA a full outer join ONPREM_DATA b on lower(a.col) = lower(b.col)
   ORDER BY cloud , onprem DESC
   ;