#include <stdbool.h>
#include <stdint.h>

#ifndef __TKEY_H__
#define __TKEY_H__ // Include guard

    #ifdef __cplusplus // Required for C++ compiler
    extern "C" {
    #endif

        //Forward Declarations
        struct ShareStore;
        struct ShareStoreMap;
        struct ShareStorePolyIDShareIndexMap;
        struct FFIStorageLayer;
        struct KeyReconstructionDetails;
        struct ServiceProvider;
        struct Metadata;
        struct LocalMetadataTransitions;
        struct KeyDetails;
        struct KeyPoint;
        struct ShareTransferStore;
        struct GenerateShareStoreResult;
        struct LocalMetadataTransitions;
        struct Polynomial;
        struct PublicPolynomial;
        struct ShareMap;
        struct ShareStoreArray;
        struct KeyPointArray;
        struct TssOptions;
        struct NodeDetails;
        struct FFIRssComm;
        struct ServerOpts;
        //Methods
        char* get_version(int* error_code);
        void string_free(char *ptr);
        char* generate_private_key( char* curve_n, int* error_code);
        char* private_to_public( char* secret, int* error_code);
        struct Polynomial* lagrange_interpolate_polynomial(struct KeyPointArray* points, char* curve_n, int* error_code);
        char* key_point_get_x(struct KeyPoint* point, int* error_code);
        struct KeyPoint* key_point_new(char* x, char* y, int* error_code);
        struct KeyPoint* key_point_new_addr(char* address, int* error_code);
        char* key_point_get_y(struct KeyPoint* point, int* error_code);
        char* key_point_encode(struct KeyPoint* point, char* enc, int* error_code);
        void key_point_free(struct KeyPoint* point);
        char* key_reconstruction_get_private_key(struct KeyReconstructionDetails* key_details, int* error_code);
        int key_reconstruction_get_seed_phrase_len(struct KeyReconstructionDetails* key_details, int* error_code);
        char* key_reconstruction_get_seed_phrase_at(struct KeyReconstructionDetails* key_details, int at, int* error_code);
        int key_reconstruction_get_all_keys_len(struct KeyReconstructionDetails* key_details, int* error_code);
        char* key_reconstruction_get_all_keys_at(struct KeyReconstructionDetails* key_details, int at, int* error_code);
        void key_reconstruction_details_free(struct KeyReconstructionDetails* key_details);
        struct KeyPoint* key_details_get_pub_key_point(struct KeyDetails* key_details, int* error_code);
        int key_details_get_required_shares(struct KeyDetails* key_details, int* error_code);
        unsigned int key_details_get_threshold(struct KeyDetails* key_details, int* error_code);
        unsigned int key_details_get_total_shares(struct KeyDetails* key_details, int* error_code);
        char* key_details_get_share_descriptions(struct KeyDetails* key_details, int* error_code);
        void key_details_free(struct KeyDetails* key_details);
        struct ShareStore* share_store_from_json(char* json, int* error_code);
        char* share_store_to_json(struct ShareStore* store, int* error_code);
        char* share_store_get_share(struct ShareStore* store, int* error_code);
        char* share_store_get_share_index(struct ShareStore* store, int* error_code);
        char* share_store_get_polynomial_id(struct ShareStore* store, int* error_code);
        void share_store_free(struct ShareStore* ptr);
        struct FFIStorageLayer* storage_layer(bool enable_logging, char* host_url, long long int server_time_offset, char* (*network_callback)(char*, char*, void*, int*), void* parent_instance_ref, int* error_code);
        void* storage_layer_free(struct FFIStorageLayer* ptr);
        struct ServiceProvider* service_provider(bool enable_logging, char* postbox_key, char* curve_n, bool use_tss, char* verifier_name, char* verifier_id, struct NodeDetails* tss_node_details, struct NodeDetails* rss_node_details,struct NodeDetails* sss_node_details, int* error_code);
        void service_provider_free(struct ServiceProvider* prt);
        struct FFIThresholdKey* threshold_key(struct Metadata* metadata, struct ShareStorePolyIDShareIndexMap* shares, struct FFIStorageLayer* storage_layer, struct ServiceProvider* service_provider, struct LocalMetadataTransitions* local_metadata_transitions, struct Metadata* last_fetch_cloud_metadata, bool enable_logging, bool manual_sync, struct FFIRssComm* rss_comm, int* error_code);
        struct KeyDetails* threshold_key_initialize(struct FFIThresholdKey* threshold_key, char* import_share, struct ShareStore* input, bool never_initialize_new_key, bool include_local_metadata_transitions, char* curve_n, bool use_tss, char* device_share, int* device_tss_index, struct KeyPoint* factor_pub, int* error_code);
        struct KeyDetails* threshold_key_get_key_details(struct FFIThresholdKey* threshold_key, int* error_code);
        struct KeyReconstructionDetails* threshold_key_reconstruct(struct FFIThresholdKey* threshold_key, char* curve_n, int* error_code);
        void threshold_key_free(struct FFIThresholdKey* ptr);
        char* share_store_map_get_keys(struct ShareStoreMap* map, int* error_code);
        struct ShareStore* share_store_map_get_value_by_key(struct ShareStoreMap* map, char* key, int* error_code);
        void share_store_map_free(struct ShareStoreMap* ptr);
        char* share_store_poly_id_index_map_get_keys(struct ShareStorePolyIDShareIndexMap* map, int* error_code);
        struct ShareStoreMap* share_store_poly_id_index_map_get_value_by_key(struct ShareStorePolyIDShareIndexMap* map, char* key, int* error_code);
        char* generate_new_share_store_result_get_shares_index(struct GenerateShareStoreResult* result,int* error_code);
        struct ShareStoreMap* generate_new_share_store_result_get_share_store_map(struct GenerateShareStoreResult* result,int* error_code);
        void generate_share_store_result_free(struct GenerateShareStoreResult* ptr);
        void share_store_poly_id_index_map_free(struct ShareStorePolyIDShareIndexMap* ptr);
        struct GenerateShareStoreResult* threshold_key_generate_share(struct FFIThresholdKey* threshold_key, char* curve_n, bool use_tss, struct TssOptions* tss_options, int* error_code);
        void threshold_key_import_tss_key(struct FFIThresholdKey* threshold_key, bool update_metadata, char* tss_tag, char* import_key, struct KeyPoint* factor_pub, int new_tss_index, struct ServerOpts* server_opts, char* curve_n, int* error_code);
        void threshold_key_delete_share(struct FFIThresholdKey* threshold_key, char* share_index, char* curve_n, bool use_tss, struct TssOptions* tss_options, int* error_code);
        void threshold_key_delete_tkey(struct FFIThresholdKey* threshold_key, char* curve_n, int* error_code);
        char* threshold_key_output_share(struct FFIThresholdKey* threshold_key, char* share_index, char* share_type, char* curve_n, int* error_code);
        char* threshold_key_get_tkey_store(struct FFIThresholdKey* threshold_key, char* module_name, int* error_code);
        char* threshold_key_get_tkey_store_item(struct FFIThresholdKey* threshold_key, char* module_name, char* identifier, int* error_code);
        void threshold_key_input_share(struct FFIThresholdKey* threshold_key, char* share, char* share_type, char* curve_n, int* error_code);
        struct ShareStore* threshold_key_output_share_store(struct FFIThresholdKey* threshold_key, char* share_index, char* poly_id, char* curve_n, int* error_code);
        void threshold_key_input_share_store(struct FFIThresholdKey* threshold_key, struct ShareStore* share_store, int* error_code);
        char* threshold_key_get_shares_indexes(struct FFIThresholdKey* threshold_key, int* error_code);
        char* threshold_key_encrypt(struct FFIThresholdKey* threshold_key, char* data, char* curve_n, int* error_code);
        char* threshold_key_decrypt(struct FFIThresholdKey* threshold_key, char* data, int* error_code);
        struct LocalMetadataTransitions* threshold_key_get_local_metadata_transitions(struct FFIThresholdKey* threshold_key, int* error_code);
        struct Polynomial* threshold_key_reconstruct_latest_poly(struct FFIThresholdKey *threshold_key, char* curve_n, int* error_code);
        struct Metadata* threshold_key_get_last_fetched_cloud_metadata(struct FFIThresholdKey* threshold_key, int* error_code);
        void threshold_key_sync_local_metadata_transitions(struct FFIThresholdKey *threshold_key, char* curve_n, int* error_code);
        struct ShareStoreArray* threshold_key_get_all_share_stores_for_latest_polynomial(struct FFIThresholdKey* threshold_key, char* curve_n, int* error_code);
        struct ShareStorePolyIDShareIndexMap* threshold_key_get_shares(struct FFIThresholdKey* threshold_key, int* error_code);

        char* threshold_key_get_metadata(struct FFIThresholdKey* threshold_key, char* private_key, int* error_code);
        void threshold_key_set_metadata(struct FFIThresholdKey* threshold_key, char* private_key, char* value, char* curve_n, int* error_code);
        void threshold_key_set_metadata_stream(struct FFIThresholdKey* threshold_key, char* private_keys, char* values, char* curve_n, int* error_code);
        void threshold_key_service_provider_assign_tss_public_key(struct FFIThresholdKey* threshold_key, char* tss_tag, char* tss_nonce, char* tss_public_key, int* error_code);
        // Tss

        char* threshold_key_get_tss_public_key(struct FFIThresholdKey* threshold_key, int* error_code );
        char* threshold_key_get_all_tss_tags(struct FFIThresholdKey* threshold_key, int* error_code );
        char* threshold_key_get_tss_tag_factor_pub(struct FFIThresholdKey* threshold_key, int* error_code );
        char* threshold_key_get_extended_verifier_id(struct FFIThresholdKey* threshold_key, int* error_code );

        void threshold_key_set_tss_tag(struct FFIThresholdKey* threshold_key, char* tss_tag, int* error_code );
        char* threshold_key_get_tss_tag(struct FFIThresholdKey* threshold_key, int* error_code );
        void threshold_key_create_tagged_tss_share(struct FFIThresholdKey* threshold_key, char* device_tss_share, char* factor_pub, int device_tss_index, char* curve_n, int* error_code );
        char* threshold_key_get_tss_share(struct FFIThresholdKey* threshold_key, char* factor_key, int threshold, char* curve_n, int* error_code);

        int threshold_key_get_tss_nonce(struct FFIThresholdKey* threshold_key, char* tss_tag, int* error_code );
        void threshold_key_copy_factor_pub(struct FFIThresholdKey* threshold_key, char* new_factor_pub, int new_tss_index, char* factor_pub, char* curve_n, int* error_code );

        void threshold_key_generate_tss_share(struct FFIThresholdKey* threshold_key, char* input_tss_share, int input_tss_index, int new_tss_index, char* new_factor_pub, char* selected_servers, char* auth_signatures, char* curve_n, int* error_code );
        void threshold_key_delete_tss_share(struct FFIThresholdKey* threshold_key, char* input_tss_share, int input_tss_index, char* factor_pub, char* selected_servers, char* auth_signatures, char* curve_n, int* error_code );
        // share description
        char* threshold_key_get_share_descriptions(struct FFIThresholdKey* threshold_key, int* error_code);
        void threshold_key_add_share_description(struct FFIThresholdKey* threshold_key, char* key, char* description, bool update_metadata, char* curve_n, int* error_code);
        void threshold_key_delete_share_description(struct FFIThresholdKey* threshold_key, char* key, char* description, bool update_metadata, char* curve_n, int* error_code);
        void threshold_key_update_share_description(struct FFIThresholdKey* threshold_key, char* key, char* old_description, char* new_description, bool update_metadata, char* curve_n, int* error_code);
        struct ShareStore* threshold_key_share_to_share_store(struct FFIThresholdKey* threshold_key, char* share, char* curve_n, int* error_code);
        struct Metadata* threshold_key_get_current_metadata(struct FFIThresholdKey* threshold_key, int* error_code);
        //Module: security-question
        struct GenerateShareStoreResult* security_question_generate_new_share(struct FFIThresholdKey* threshold_key, char* questions, char* answer, char* curve_n, int* error_code);
        bool security_question_input_share(struct FFIThresholdKey* threshold_key, char* answer, char* curve_n, int* error_code);
        bool security_question_change_question_and_answer(struct FFIThresholdKey* threshold_key, char* questions, char* answer, char* curve_n, int* error_code);
        bool security_question_store_answer(struct FFIThresholdKey* threshold_key, char* answer, char* curve_n, int* error_code);
        char* security_question_get_answer(struct FFIThresholdKey* threshold_key, int* error_code);
        char* security_question_get_questions(struct FFIThresholdKey* threshold_key, int* error_code);
        //Module: share-transfer
        void share_transfer_store_free(struct ShareTransferStore* ptr);
        char* share_transfer_request_new_share(struct FFIThresholdKey* threshold_key, char* user_agent, char* available_share_indexes, char* curve_n, int* error_code);
        void share_transfer_add_custom_info_to_request(struct FFIThresholdKey* threshold_key, char* enc_pub_key_x, char* custom_info, char* curve_n, int* error_code);
        char* share_transfer_look_for_request(struct FFIThresholdKey* threshold_key, int* error_code);
        void share_transfer_approve_request(struct FFIThresholdKey* threshold_key, char* enc_pub_key_x, struct ShareStore* share_store, char* curve_n, int* error_code);
        void share_transfer_approve_request_with_share_indexes(struct FFIThresholdKey* threshold_key, char* enc_pub_key_x, char* share_indexes, char* curve_n, int* error_code);
        struct ShareTransferStore* share_transfer_get_store(struct FFIThresholdKey* threshold_key, int* error_code);
        bool share_transfer_set_store(struct FFIThresholdKey* threshold_key, struct ShareTransferStore* store, char* curve_n, int* error_code);
        bool share_transfer_delete_store(struct FFIThresholdKey* threshold_key, char* enc_pub_key_x, char* curve_n, int* error_code);
        char* share_transfer_get_current_encryption_key(struct FFIThresholdKey* threshold_key, int* error_code);
        struct ShareStore* share_transfer_request_status_check(struct FFIThresholdKey* threshold_key, char* enc_pub_key_x, bool delete_request_on_completion, char* curve_n, int* error_code);
        void share_transfer_cleanup_request(struct FFIThresholdKey* threshold_key, int* error_code);
        //Module:seed-phrase
        void seed_phrase_set_phrase(struct FFIThresholdKey* threshold_key,char* format,char* phrase, unsigned int number_of_wallets,char* curve_n, int* error_code);
        void seed_phrase_change_phrase(struct FFIThresholdKey* threshold_key,char* old_phrase,char* new_phrase,char* curve_n, int* error_code);
        void seed_phrase_delete_seed_phrase(struct FFIThresholdKey* threshold_key, char* seed_phrase, int* error_code);
        char* seed_phrase_get_seed_phrases(struct FFIThresholdKey* threshold_key, int* error_code);
        //(removed) char* seed_phrase_get_seed_phrases_with_accounts(struct FFIThresholdKey* threshold_key, char* derivation_path, int* error_code);
        //(removed) char* seed_phrase_get_accounts(struct FFIThresholdKey* threshold_key, char* derivation_path, int* error_code);
        //Module: private-keys
        bool private_keys_set_private_key(struct FFIThresholdKey* threshold_key, char* key, char* format, char* curve_n, int* error_code);
        char* private_keys_get_private_keys(struct FFIThresholdKey* threshold_key, int* error_code);
        char* private_keys_get_accounts(struct FFIThresholdKey* threshold_key, int* error_code);
        // metadata
        void metadata_free(struct Metadata* metadata);
        struct Metadata* metadata_from_json(char* json, int* error_code);
        char* metadata_to_json(struct Metadata* metadata, int* error_code);
        // polynomial
        struct Polynomial* polynomial(char* polynomials, struct PublicPolynomial* public_polynomial, int* error_code);
        struct ShareMap* polynomial_generate_shares(struct Polynomial* polynomial, char* share_indexes, char* curve_n, int* error_code);
        struct PublicPolynomial* polynomial_get_public_polynomial(struct Polynomial* polynomial, int* error_code);
        void polynomial_free(struct Polynomial* polynomial);
        // public polynomial
        unsigned int public_polynomial_get_threshold(struct PublicPolynomial* public_polynomial, int* error_code);
        struct KeyPoint* public_polynomial_poly_commitment_eval(struct PublicPolynomial* public_polynomial, char* index, char* curve_n,int* error_code);
        void public_polynomial_free(struct PublicPolynomial* public_polynomial);
        // share map
        void share_map_free(struct ShareMap* share_map);
        char* share_map_get_share_keys(struct ShareMap* share_map, int* error_code);
        char* share_map_get_share_by_key(struct ShareMap* share_map, char* key, int* error_code);
        //LocalMetadataTransitions
        void local_metadata_transitions_free(struct LocalMetadataTransitions* transitions);
        struct LocalMetadataTransitions* local_metadata_transitions_from_json(char* json, int* error_code);
        char* local_metadata_transitions_to_json(struct LocalMetadataTransitions* local_metadata_transitions, int* error_code);
        //share serialization
        char* share_serialization_serialize_share(struct FFIThresholdKey* threshold_key, char* share, char* format, int* error_code);
        char* share_serialization_deserialize_share(struct FFIThresholdKey* threshold_key, char* share, char* format, int* error_code);
        // share store array
        int share_store_array_get_len(struct ShareStoreArray* share_stores, int* error_code);
        struct ShareStore* share_store_array_get_value_by_index(struct ShareStoreArray* share_stores, int index, int* error_code);
        void share_store_array_free(struct ShareStoreArray* ptr);
        // key point array
        struct KeyPointArray* key_point_array_new(void);
        void key_point_array_insert(struct KeyPointArray* key_point_array, struct KeyPoint* point, int* error_code);
        void key_point_array_update_at_index(struct KeyPointArray* key_point_array, int index, struct KeyPoint* point, int* error_code);
        void key_point_array_remove(struct KeyPointArray* key_point_array, int index, int* error_code);
        int key_point_array_get_len(struct KeyPointArray* key_point_array, int* error_code);
        struct KeyPoint* key_point_array_get_value_by_index(struct KeyPointArray* key_point_array, int index, int* error_code);
        void key_point_array_free(struct KeyPointArray* ptr);
        // TssOptions
        struct TssOptions* tss_options(char* input_tss_share, int input_tss_index, struct KeyPoint* factor_pub, char* auth_signatures, char* selected_servers, int* new_tss_index, struct KeyPoint* new_factor_pub, int* error_code);
        void tss_options_free(struct TssOptions* ptr);
        //NodeDetails
        struct NodeDetails* node_details(char* server_endpoints, char* server_public_keys, int server_threshold, int* error_code);
        void node_details_free(struct NodeDetails* ptr);
        //RssComm
        struct FFIRSSComm* rss_comm(char* (*network_callback)(char*, char*, void*, int*), void* parent_instance_ref, int* error_code);
        void* rss_comm_free(struct FFIRssComm* ptr);
    #ifdef __cplusplus
    } // extern "C"
    #endif
#endif // __TKEY_H__
