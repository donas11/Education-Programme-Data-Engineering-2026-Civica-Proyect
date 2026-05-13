with 

source as (

    select * from {{ source('bronze_raw', 'llm_complete_dataset') }}

),

renamed as (

    select *

    from source

)

select * from renamed