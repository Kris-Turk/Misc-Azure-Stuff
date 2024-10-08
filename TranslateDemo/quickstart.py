from azure.ai.translation.text import TextTranslationClient
from azure.identity import DefaultAzureCredential

region = "australiaeast"
resource_id = "/subscriptions/xxxxxxxxxxxxxxxxxx/resourceGroups/rg-xxx/providers/Microsoft.CognitiveServices/accounts/xxx"
endpoint = "https://xxx.cognitiveservices.azure.com/" # not rqeuired if public endpoint is used, only required for private endpoints

# [START create_text_translation_client_with_entra_id_token]
credential = DefaultAzureCredential()
text_translator = TextTranslationClient(credential=credential, region=region, resource_id=resource_id, endpoint=endpoint)

input_text_elements = ["This is my brother, and my father"]
to_language = ["es"]


text_translator.translate(body=input_text_elements, to_language=to_language)
# [END create_text_translation_client_with_entra_id_token]
