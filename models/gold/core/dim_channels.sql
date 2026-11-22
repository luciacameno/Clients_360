select channel_key, channel_name
from (values
    ('tienda', 'Tienda física'),
    ('web',    'Web'),
    ('app',    'App')
) as channels (channel_key, channel_name)