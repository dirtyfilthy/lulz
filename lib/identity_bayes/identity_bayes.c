#include <stdio.h>
#include <sqlite3.h>
#include <ctype.h>
#include <gmp.h>
#include "ruby.h"
#include "uthash.h"

#define DB_NULL_ID -1
#define DB_HARD_NULL_ID -2
#define MINIMUM_RESULTS 20
#define MATCH_NONE 0
#define MATCH_PARTIAL 1
#define MATCH_FULL 2
static int subject_sym;
static int  object_sym;
static int  object_id_sym;
static int creator_sym;
static int name_sym;
static int klass_sym;
static int type_sym;
static int to_s_sym;
static int bayes_predicate_sym;
static int predicates_sym;
static int to_cutout_sym;
static int relationship_sym;
static int id_sym;
static int clique_sym;


static sqlite3 *db;
static sqlite3 *hd_db;
static mpq_t MPQ_ONE;
typedef struct {
   int id;
   int subject_type_db_id;
   int object_type_db_id;
   int relationship_db_id;
   int created_by_db_id;
	int clique;
	int is_single_fact;
} PredicateCutout;

typedef struct  {
   unsigned int id;
   char * name;
   UT_hash_handle hh;
} ObjectType;

static ObjectType *object_types=NULL;


typedef struct  {
   unsigned int id;
   char * name;
   UT_hash_handle hh;
} Relationship;

static Relationship *relationships=NULL;

typedef struct {
   unsigned int same;
   unsigned int different;
} MatchResult;


typedef struct {
	int pred_1_id;
	int pred_2_id;
	unsigned char match_type;
	int same;
	int different;
	UT_hash_handle hh;
} EvidenceCache;


typedef struct {
	int pred_1_ob;
	int pred_2_ob;
	int pred_1_rel;
	int pred_2_rel;
	int match_type;
	int same;
	int different;
	UT_hash_handle hh;
} GeneralisedEvidenceCache;


static EvidenceCache *evidence_cache=NULL;
static GeneralisedEvidenceCache *generalised_evidence_cache=NULL;

typedef struct {
  int id;
  PredicateCutout *pred_1;
  PredicateCutout *pred_2;
  char *obj1_string;
  char *obj2_string;
  unsigned char match_type;
  unsigned char is_single_fact;
  MatchResult *match_result;
  
  mpq_t likelyhood_ratio; 
  int same;
  int different;
} Evidence;


static MatchResult *total_match_cache=NULL;
static MatchResult *total_evidence_cache=NULL;


/* FUNCTIONS */

static void update_evidence(int id, int match);


char *trim (char *str)
{
   char *ibuf, *obuf;

   if (str)
   {
      for (ibuf = obuf = str; *ibuf; )
      {
	 while (*ibuf && (isspace (*ibuf)))
	    ibuf++;
         if (*ibuf && (obuf != str))
	    *(obuf++) = ' ';
         while (*ibuf && (!isspace (*ibuf)))
	    *(obuf++) = *(ibuf++);
      }
      obuf = NULL;
   }
   return (str);
}


static void dynamic_strcat(char **str_1, const char *str_2){
   char *str_3; 
   if(*str_1==NULL){
      *str_1=(char *) calloc(1, sizeof(char));
   }
   str_3 = (char *) calloc(strlen(*str_1) + strlen(str_2) + 1, sizeof(char));
   memcpy(str_3,*str_1,strlen(*str_1));
   strcat(str_3,str_2);
   
   free(*str_1);
   *str_1=str_3; 
}



static char* predicate_where_conditions(char *table_prefix, PredicateCutout *pred){
   char *where=NULL;
   char *buffer=calloc(34,sizeof(char));
   char *term;
   unsigned char first=1;
   int i, value;
   dynamic_strcat(&where,"(");
   for(i=0;i<4;i++){
      switch(i) {
	 case 0:
	    term=".object_type_id = ";
	    value=pred->object_type_db_id;
	    break;
	 case 1:
	    term=".relationship_id = ";
	    value=pred->relationship_db_id;
	    break;
	 case 2:
	    term=".subject_type_id = ";
	    value=pred->subject_type_db_id;
	    break;
	 case 3:
	    term=".created_by_id = ";
	    value=pred->created_by_db_id;
	    break;
	 default:
	    printf("We should never reach here!");
	    abort();
      }
      if(value != DB_NULL_ID){
			if(!first){
				dynamic_strcat(&where," AND ");
			}
	 dynamic_strcat(&where, table_prefix);
	 dynamic_strcat(&where, term);
	 snprintf(buffer,34,"%d",value);
	 dynamic_strcat(&where, buffer);      
	 first=0;
      }
   }
   free(buffer);
   dynamic_strcat(&where, " )");
   return where;
}

static void swap_ptr(void **a, void **b){
   void *c;
   c=*a;
   *a=*b;
   *b=c;
}

static void generalise_predicate(PredicateCutout *pred, int level){
 

   switch(level){
      case 0:
	 break;
    case 3:
	 pred->object_type_db_id=DB_NULL_ID;
	 break;
            
    case 2:

	 pred->relationship_db_id=DB_NULL_ID;
	 break;
	  
	 
    case 1:
	 
	 pred->subject_type_db_id=DB_NULL_ID;
	 
	 pred->created_by_db_id=DB_NULL_ID;
	 break;
	 default:
	 printf("We should never reach here!");
	 abort();
   }
}

static void order_predicates(PredicateCutout **pred_ptr_1, PredicateCutout **pred_ptr_2){
   PredicateCutout *pred_1=*pred_ptr_1;
   PredicateCutout *pred_2=*pred_ptr_2;
   int i,val_1,val_2;
      if(pred_1->id > pred_2->id){
	 swap_ptr((void **) pred_ptr_1, (void **) pred_ptr_2);
	 return;     
      }
      else if(val_1 < val_2) {
	 return;
      }
}



long last_row_id(const char *table){
   char *sql=NULL;
   int rc,id;
   sqlite3_stmt *statement;
   dynamic_strcat(&sql,"SELECT ROWID FROM ");
   dynamic_strcat(&sql,table);
   dynamic_strcat(&sql," ORDER BY ROWID DESC LIMIT 1");
   sqlite3_prepare_v2(db, sql, strlen(sql), &statement, NULL);
   free(sql);
   rc=sqlite3_step(statement);
   if(rc==SQLITE_ERROR){
      rb_raise(rb_eRuntimeError, sqlite3_errmsg(db));
   }
   id=sqlite3_column_int(statement,0);
   sqlite3_finalize(statement);
   return id;
			   


}

static void find_or_create_predicate_cutout(PredicateCutout *pred){
	char *sql=NULL;
	char *where=predicate_where_conditions("predicate_cutouts", pred);
	sqlite3_stmt *statement;
	int rc;
	dynamic_strcat(&sql,"SELECT id FROM predicate_cutouts WHERE ");
	dynamic_strcat(&sql,where);
	dynamic_strcat(&sql, " LIMIT 1;");
	sqlite3_prepare_v2(db, sql, strlen(sql), &statement, NULL);
	rc=sqlite3_step(statement);
	if(rc==SQLITE_ERROR){
		rb_raise (rb_eRuntimeError, sqlite3_errmsg(db));
	}
	if(rc==SQLITE_ROW){
		pred->id=sqlite3_column_int(statement,0);
		free(sql);
		free(where);
		sqlite3_finalize(statement);
		return;
	}
	free(sql);
	free(where);
	sqlite3_finalize(statement);
	sql="INSERT INTO predicate_cutouts (object_type_id, subject_type_id, relationship_id, created_by_id) VALUES (?,?,?,?,?,?)";
	sqlite3_prepare_v2(db, sql, strlen(sql), &statement, NULL);
	sqlite3_bind_int(statement,1,pred->object_type_db_id);
	sqlite3_bind_int(statement,2,pred->subject_type_db_id);
	sqlite3_bind_int(statement,3,pred->relationship_db_id);
	sqlite3_bind_int(statement,4,pred->created_by_db_id);
	rc=sqlite3_step(statement);
	
	sqlite3_finalize(statement); 
	if(rc==SQLITE_ERROR){
		rb_raise (rb_eRuntimeError, sqlite3_errmsg(db));
	}
        pred->id=last_row_id("predicate_cutouts");
         #ifdef DEBUG
	 printf("pred last_rowid %d\n",pred->id);
	 fflush(stdout);
      #endif
 
}



static void find_or_create_or_update_evidence(Evidence *e, int update, int match){
	char *sql=NULL;
	sqlite3_stmt *statement;
	int rc;
	int same,different;
	sql="SELECT id,same,different FROM evidence WHERE pred_1=? AND pred_2=? AND match_type=? LIMIT 1";
	sqlite3_prepare_v2(db, sql, strlen(sql), &statement, NULL);
	sqlite3_bind_int(statement,1,e->pred_1->id);
	sqlite3_bind_int(statement,2,e->pred_2->id);
	sqlite3_bind_int(statement,3,e->match_type);
	rc=sqlite3_step(statement);
	if(rc==SQLITE_ERROR){
		rb_raise (rb_eRuntimeError, sqlite3_errmsg(db));
	}
	if(rc==SQLITE_ROW){
		e->id=sqlite3_column_int(statement,0);
		e->same=sqlite3_column_int(statement,1);
		e->different=sqlite3_column_int(statement,2);
		sqlite3_finalize(statement);
		if(update){
			update_evidence(e->id,match);
		}
		return;
	}
	sqlite3_finalize(statement);

	sql="INSERT INTO evidence (pred_1, pred_2, match_type, same, different) VALUES (?,?,?,?,?)";
	sqlite3_prepare_v2(db, sql, strlen(sql), &statement, NULL);
	sqlite3_bind_int(statement,1,e->pred_1->id);
	sqlite3_bind_int(statement,2,e->pred_2->id);
	sqlite3_bind_int(statement,3,e->match_type);
	if(update){
		sqlite3_bind_int(statement,4,match ? 1 : 0);
		sqlite3_bind_int(statement,5,match ? 0 : 1);
	}
	else{
			
		sqlite3_bind_int(statement,4,0);
		sqlite3_bind_int(statement,5,0);
	}
	rc=sqlite3_step(statement);
	
	sqlite3_finalize(statement);
	if(rc==SQLITE_ERROR){
		rb_raise (rb_eRuntimeError, sqlite3_errmsg(db));
	}
        e->id=(long) last_row_id("evidence");
		  e->same=(match && update) ? 1 : 0;
		  e->different=(match || !update) ? 0 : 1;
 
}
static void get_evidentual_matches(MatchResult *result, Evidence *e){
   char *sql=NULL, *where_1, *where_2;
   int generalisation_level,rc;
   int s1,d1;
   int keylen;
	EvidenceCache *e_cache, *lookup;
	GeneralisedEvidenceCache *g_cache, *g_lookup;
	PredicateCutout *pred_copy_1;
   PredicateCutout *pred_copy_2;
   sqlite3_stmt *statement;
   char *tail;
    #ifdef DEBUG
	 printf("getting evidentual matches\n");
	 fflush(stdout);
   #endif

   if(e->match_result!=NULL){
    #ifdef DEBUG
	 printf("using cached match\n");
	 fflush(stdout);
      #endif

      result->same=e->match_result->same;
      result->different=e->match_result->different;
		return;
   }


	
	
	keylen = offsetof(EvidenceCache, match_type)       /* offset of last key field */
		      + sizeof(unsigned char)             /* size of last key field */
				- offsetof(EvidenceCache, pred_1_id);  /* offset of first key field */
	lookup=(EvidenceCache*) calloc(1, sizeof(EvidenceCache));
	lookup->pred_1_id=e->pred_1->id;
	lookup->pred_2_id=e->pred_2->id;
	lookup->match_type=e->match_type;
	HASH_FIND( hh, evidence_cache, &lookup->pred_1_id, keylen, e_cache );
	free(lookup);

	if(e_cache){
		result->same=e_cache->same;
		result->different=e_cache->different;
				
    #ifdef DEBUG
	 printf("using ECACHED match\n");
	 fflush(stdout);
      #endif
		return;
	}
	
	keylen = offsetof(GeneralisedEvidenceCache, match_type)       /* offset of last key field */
		      + sizeof(int)             /* size of last key field */
				- offsetof(GeneralisedEvidenceCache, pred_1_ob);  /* offset of first key field */
   pred_copy_1=memcpy((PredicateCutout *) malloc(sizeof(PredicateCutout)), e->pred_1, sizeof(PredicateCutout));
   pred_copy_2=memcpy((PredicateCutout *) malloc(sizeof(PredicateCutout)), e->pred_2, sizeof(PredicateCutout));
  
   #ifdef DEBUG
	 printf("PRED COPY TYPES %d %d\n", pred_copy_1->object_type_db_id, pred_copy_2->object_type_db_id);
	 fflush(stdout);
   #endif


	
   if(e->match_type!=MATCH_NONE){
      result->same=10;
      result->different=5;
   }
   else {
      result->same=5;
      result->different=10;
   }
	find_or_create_or_update_evidence(e,0,0);
	
	if((e->same+e->different) > MINIMUM_RESULTS){
		result->same=e->same;
		result->different=e->different;	
	}
	else{
		sql=NULL;
	
		g_lookup=(GeneralisedEvidenceCache *) calloc(1, sizeof(GeneralisedEvidenceCache));
		g_lookup->pred_1_ob=e->pred_1->object_type_db_id;
		g_lookup->pred_2_ob=e->pred_2->object_type_db_id;
		g_lookup->pred_1_rel=e->pred_1->relationship_db_id;
		g_lookup->pred_2_rel=e->pred_2->relationship_db_id;
		g_lookup->match_type=e->match_type;
		HASH_FIND( hh, generalised_evidence_cache, &g_lookup->pred_1_ob, keylen, g_cache );
		free(g_lookup);

		if(g_cache){
			result->same=g_cache->same;
			result->different=g_cache->different;
			free(pred_copy_1);
			free(pred_copy_2);		
			#ifdef DEBUG
			printf("using GCACHED match\n");
			fflush(stdout);
			#endif

			return;
		}
		generalise_predicate(pred_copy_1, 1);
		generalise_predicate(pred_copy_2, 1);
      
		where_1=predicate_where_conditions("pred_1", pred_copy_1);
		where_2=predicate_where_conditions("pred_2", pred_copy_2);
		dynamic_strcat(&sql,"SELECT SUM(same), SUM(different) FROM evidence LEFT JOIN predicate_cutouts as pred_1 ON pred_1.id = evidence.pred_1 LEFT JOIN predicate_cutouts AS pred_2 ON pred_2.id=evidence.pred_2 WHERE match_type = ? AND ");
		dynamic_strcat(&sql,where_1);
		dynamic_strcat(&sql," AND ");
		dynamic_strcat(&sql,where_2);
		dynamic_strcat(&sql," AND evidence.id>0 AND pred_1.id<=pred_2.id");
		#ifdef DEBUG
			printf("predicate sql %s\n",sql);
			fflush(stdout);
		#endif
	
		sqlite3_prepare_v2(db, sql, strlen(sql), &statement, NULL);
		sqlite3_bind_int(statement,1,e->match_type);
		free(where_1);
		free(where_2);
		free(sql);
		rc=sqlite3_step(statement);
		if(rc==SQLITE_ERROR){
			rb_raise (rb_eRuntimeError, sqlite3_errmsg(db));
		}
		if(rc==SQLITE_ROW){
			s1=sqlite3_column_int(statement,0);
			d1=sqlite3_column_int(statement,1);
		}
		sqlite3_finalize(statement);
		if(s1+d1>MINIMUM_RESULTS){
	 
			#ifdef DEBUG
				printf("above minimum %d %d\n",s1,d1);
				fflush(stdout);
			#endif     
			result->same=s1;
			result->different=d1;
		}	


		g_cache=(GeneralisedEvidenceCache*) calloc(1, sizeof(GeneralisedEvidenceCache));
		g_cache->pred_1_ob=e->pred_1->object_type_db_id;
		g_cache->pred_2_ob=e->pred_2->object_type_db_id;
		g_cache->pred_1_rel=e->pred_1->relationship_db_id;
		g_cache->pred_2_rel=e->pred_2->relationship_db_id;
		g_cache->match_type=e->match_type;
		g_cache->same=result->same;
		g_cache->different=result->different;
	
		HASH_ADD( hh, generalised_evidence_cache , pred_1_ob, keylen, g_cache);
	}
   e->match_result=memcpy((MatchResult *) malloc(sizeof(MatchResult)), result, sizeof(MatchResult));
   e_cache=(EvidenceCache*) calloc(1, sizeof(EvidenceCache));
	e_cache->pred_1_id=e->pred_1->id;
	e_cache->pred_2_id=e->pred_2->id;
	e_cache->match_type=e->match_type;	
	e_cache->same=result->same;
	e_cache->different=result->different;
	
	HASH_ADD( hh, evidence_cache , pred_1_id, keylen, e_cache);
   free(pred_copy_1);  
   free(pred_copy_2);  
}

static void sqlite3_begin(){
   sqlite3_stmt *statement;
   int rc;
   const char *sql="BEGIN;";
   sqlite3_prepare_v2(db, sql, strlen(sql), &statement, NULL);
   rc=sqlite3_step(statement);
   sqlite3_finalize(statement);
}


static void sqlite3_commit(){
   sqlite3_stmt *statement;
   const char *sql="COMMIT;";
   int rc;
   sqlite3_prepare_v2(db, sql, strlen(sql), &statement, NULL);
   rc=sqlite3_step(statement);
   sqlite3_finalize(statement);
}

static ObjectType *get_or_create_object_type(const char *type){
   ObjectType *ot;
   sqlite3_stmt *statement;
   int rc;
   char *sql;
   HASH_FIND_STR(object_types, type, ot);
   
   if(ot==NULL){
      ot=(ObjectType *) malloc(sizeof(ObjectType));
      sql="INSERT INTO object_types (name) VALUES (?)";
      sqlite3_prepare_v2(db, sql, strlen(sql), &statement, NULL);
      sqlite3_bind_text(statement,1,type,-strlen(type),SQLITE_TRANSIENT);
      rc=sqlite3_step(statement);
      if(rc==SQLITE_ERROR){
	 rb_raise (rb_eRuntimeError, sqlite3_errmsg(db));
      }
      
      sqlite3_finalize(statement);
      ot->name=(char *) strcpy((char *) malloc(strlen(type)+1),type);
      ot->id=(long) last_row_id("object_types");
      #ifdef DEBUG
	 printf("object type last_rowid %d\n",ot->id);
	 fflush(stdout);
      #endif

      HASH_ADD_KEYPTR( hh, object_types, ot->name, strlen(ot->name), ot );
   }
   return ot;
}

static Relationship *get_or_create_relationship(const char *type){
   Relationship *r;
   sqlite3_stmt *statement;
   int rc;
   char *sql;
   HASH_FIND_STR(relationships, type, r);
   if(r==NULL){
      r=(Relationship *) malloc(sizeof(Relationship));
      sql="INSERT INTO relationships (name) VALUES (?)";
      sqlite3_prepare_v2(db, sql, strlen(sql), &statement, NULL);
      sqlite3_bind_text(statement,1,type,-strlen(type),SQLITE_TRANSIENT);
      rc=sqlite3_step(statement);
      if(rc==SQLITE_ERROR){
	 rb_raise (rb_eRuntimeError, sqlite3_errmsg(db));
      }

      sqlite3_finalize(statement);
      r->name=(char *) strcpy((char *) malloc(strlen(type)+1),type);
      r->id=(long) last_row_id("relationships");
      HASH_ADD_KEYPTR( hh, relationships, r->name, strlen(r->name), r );
       #ifdef DEBUG
	 printf("object type last_rowid %d\n",r->id);
	 fflush(stdout);
      #endif

   }
   return r;
}

void get_total_matches(MatchResult *out){
   char *sql;
   sqlite3_stmt *statement;
   int rc;
   if(total_match_cache==NULL){
      sql="SELECT same, different FROM evidence WHERE id = -978 LIMIT 1";
      sqlite3_prepare_v2(db, sql, strlen(sql), &statement, NULL);
      rc=sqlite3_step(statement);
      if(rc==SQLITE_ERROR){
	 rb_raise (rb_eRuntimeError, sqlite3_errmsg(db));
      }
      total_match_cache=(MatchResult *) malloc(sizeof(MatchResult));
      total_match_cache->same=sqlite3_column_int(statement,0);
      total_match_cache->different=sqlite3_column_int(statement,1);
      sqlite3_finalize(statement);
   }
   out->same=total_match_cache->same;
   out->different=total_match_cache->different;

}


void get_total_evidence(MatchResult *out){
   char *sql;
   sqlite3_stmt *statement;
   int rc;
   if(total_evidence_cache==NULL){
      sql="SELECT same, different FROM evidence WHERE id = -979 LIMIT 1";
      sqlite3_prepare_v2(db, sql, strlen(sql), &statement, NULL);
      rc=sqlite3_step(statement);
      if(rc==SQLITE_ERROR){
	 rb_raise (rb_eRuntimeError, sqlite3_errmsg(db));
      }
      total_evidence_cache=(MatchResult *) malloc(sizeof(MatchResult));
      total_evidence_cache->same=sqlite3_column_int(statement,0);
      total_evidence_cache->different=sqlite3_column_int(statement,1);
      sqlite3_finalize(statement);
   }
   out->same=total_match_cache->same;
   out->different=total_match_cache->different;

}

void set_likelyhood_ratio(Evidence *e){
   mpq_t evidence_given_same, evidence_given_different, same_X_prior,temp_1, one_minus_prior;
   MatchResult match_result;
   MatchResult total_matches;
   MatchResult total_evidence;
   mpq_init(evidence_given_same);
   mpq_init(evidence_given_different);
	mpq_init(e->likelyhood_ratio);
	get_total_evidence(&total_evidence);
	get_evidentual_matches(&match_result,e);	
	if(match_result.different==0){
		match_result.different=1;
	}	
   mpq_set_ui(evidence_given_same,match_result.same,total_evidence.same);
   mpq_set_ui(evidence_given_different,match_result.different,total_evidence.different);
   mpq_canonicalize(evidence_given_same);
   mpq_canonicalize(evidence_given_different);
	mpq_div(e->likelyhood_ratio,evidence_given_same,evidence_given_different);	
	mpq_clear(evidence_given_same);
	mpq_clear(evidence_given_different);	
}

void calculate_posterior_probability(mpq_t posterior, mpq_t prior, Evidence *e){
   mpq_t evidence_given_same, evidence_given_different, same_X_prior,temp_1, one_minus_prior;
   MatchResult match_result;
   MatchResult total_matches;
   MatchResult total_evidence;
   mpq_init(evidence_given_same);
   mpq_init(evidence_given_different);
   mpq_init(same_X_prior);
   mpq_init(temp_1);
   mpq_init(one_minus_prior);
    #ifdef DEBUG
	 printf("calculating posterior");
	 fflush(stdout);
   #endif
 
	get_total_evidence(&total_evidence);
   get_evidentual_matches(&match_result,e);
  
	/* the law of CROMWELL \m/ */

	if(mpq_sgn(prior)==0){
		mpq_set_ui(prior,1,999999999);
	}

	
   /* ((evidence_given_same*prior)  /  ( (evidence_given_same*prior)  +  (evidence_given_different * (1-prior)) )); */

   mpq_set_ui(evidence_given_same,match_result.same,total_evidence.same);
   mpq_set_ui(evidence_given_different,match_result.different,total_evidence.different);
   mpq_canonicalize(evidence_given_same);
   mpq_canonicalize(evidence_given_different);
   mpq_mul(same_X_prior,evidence_given_same,prior);
   mpq_sub(one_minus_prior,MPQ_ONE,prior);
   mpq_mul(temp_1,evidence_given_different,one_minus_prior);
   mpq_add(temp_1,temp_1,same_X_prior);
   mpq_div(posterior,same_X_prior,temp_1);
	#ifdef DEBUG
		printf("show ur working...\n");
		printf("evidence given same: ");
		mpq_out_str (stdout, 10, evidence_given_same);
		printf("\nevidence given different: ");
		mpq_out_str (stdout, 10, evidence_given_different);
		printf("\ntop line: ");
		mpq_out_str (stdout, 10, same_X_prior);
		printf("\nbottom line: ");
		mpq_out_str (stdout, 10, temp_1);
		printf("\n");
	#endif

   mpq_clear(evidence_given_same);
   mpq_clear(evidence_given_different);
   mpq_clear(same_X_prior);
   mpq_clear(temp_1);
   mpq_clear(one_minus_prior);

   
       
}	


static int set_database(char *database){
	return sqlite3_open_v2(database, &db, SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX, NULL);
	//sqlite3_open_v2(":memory:", &db, SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX, NULL);
	//loadOrSaveDb(db, database, 0);
}


static unsigned char get_match_type(Evidence *e){
   int i;
   unsigned char type=MATCH_NONE;
   
   

 
   if(strcasecmp(e->obj1_string,e->obj2_string)==0){
      #ifdef DEBUG
      printf("MATCH FULL\n");
      fflush(stdout);
   #endif
 
      type=MATCH_FULL;
   }
   else if((strlen(e->obj1_string)>3 && strlen(e->obj2_string)>3) && ( strstr(e->obj1_string,e->obj2_string) || strstr(e->obj2_string,e->obj1_string) )){
         #ifdef DEBUG
      printf("MATCH PARTIAL\n");
      fflush(stdout);
   #endif
 

      type=MATCH_PARTIAL;
   }
   #ifdef DEBUG
      printf("freeing strdup\n");
      fflush(stdout);
   #endif

   return type;
}

static VALUE method_set_database(VALUE self, VALUE database){
   int rc,len;
   char *sql;
   const char *temp;
   const char *err;
   sqlite3_stmt *statement;
   Check_Type(database, T_STRING);
   rc = set_database(RSTRING_PTR(database));
   if( rc ){
      err=sqlite3_errmsg(db);
      sqlite3_close(db);
      db=NULL;
      rb_raise (rb_eRuntimeError, err);
   }
   
   /* read in cache of object types */

   sql="SELECT id, name FROM object_types";
   sqlite3_prepare_v2(db, sql, strlen(sql), &statement, NULL);   
   while((rc=sqlite3_step(statement))==SQLITE_ROW){
      ObjectType *ot=(ObjectType *) malloc(sizeof(ObjectType));
      ot->id=sqlite3_column_int(statement,0);
      temp=sqlite3_column_text(statement,1);
      len=sqlite3_column_bytes(statement,1);
      ot->name=(char *) memcpy((char *) malloc(len),temp,len);
      HASH_ADD_KEYPTR( hh, object_types, ot->name, strlen(ot->name), ot );

   }
   if(rc==SQLITE_ERROR){
      rb_raise (rb_eRuntimeError, sqlite3_errmsg(db));
   }
   sqlite3_finalize(statement); 
   
   /* read in cache of relationships */

   sql="SELECT id, name FROM relationships";
   sqlite3_prepare_v2(db, sql, strlen(sql), &statement, NULL);   
   while((rc=sqlite3_step(statement))==SQLITE_ROW){
      Relationship *ot=(Relationship *) malloc(sizeof(Relationship));
      ot->id=sqlite3_column_int(statement,0);
      temp=sqlite3_column_text(statement,1);
      len=sqlite3_column_bytes(statement,1);
      ot->name=(char *) memcpy((char *) malloc(len),sqlite3_column_text(statement,1),len);
      HASH_ADD_KEYPTR( hh, relationships, ot->name, strlen(ot->name), ot );

   }
   if(rc==SQLITE_ERROR){
      rb_raise (rb_eRuntimeError, sqlite3_errmsg(db));
   }
   sqlite3_finalize(statement); 
	return Qnil;
}



   


void free_evidence(Evidence *e){
   #ifdef DEBUG
      printf("freeing evidence\n");
      fflush(stdout);
   #endif

   free(e->pred_1);
   free(e->pred_2);
	free(e->obj1_string);
	free(e->obj2_string);
   if(e->match_result!=NULL){
      free(e->match_result);
   }
   free(e); 
}

static void hard_ruby_predicate_2_predicate_cutout(VALUE rb_predicate, PredicateCutout *p){
   VALUE r2,s2;
   VALUE cutout;
	VALUE object;
   /* int obj_id=FIX2INT(rb_ivar_get(rb_predicate,obj_id_sym))->ptr; */
   const char *creator;
   char *extra;
   #ifdef DEBUG
      printf("in hard_ruby\n");
      extra=RSTRING_PTR(rb_funcall(rb_predicate,to_s_sym,0));

      printf("processing predicate %s \n", extra);
      object=rb_ivar_get(rb_predicate,object_sym);
		
		fflush(stdout);
		extra=RSTRING_PTR(rb_funcall(object,to_s_sym,0));
		
		fflush(stdout);
		printf("object %s \n", extra);
		
		fflush(stdout);
	#endif

   cutout=rb_funcall(rb_predicate,to_cutout_sym,0);
   #ifdef DEBUG
      printf("after get cutout\n");
		
      fflush(stdout);
   #endif 
   
   p->created_by_db_id=FIX2INT(rb_funcall(cutout,creator_sym,0));
   #ifdef DEBUG
      printf("created %d\n",p->created_by_db_id);
      fflush(stdout);
   #endif 
   

   p->object_type_db_id=FIX2INT(rb_funcall(cutout,object_id_sym,0));
    #ifdef DEBUG
      printf("object %d\n",p->object_type_db_id);
      fflush(stdout);
   #endif 
   p->clique=FIX2INT(rb_funcall(rb_predicate,clique_sym,0)); 
   
    #ifdef DEBUG
      printf("got clique %d\n",p->clique);
      fflush(stdout);
   #endif 
	p->subject_type_db_id=FIX2INT(rb_funcall(cutout,subject_sym,0));
   p->relationship_db_id=FIX2INT(rb_funcall(cutout,relationship_sym,0));
   p->id=FIX2INT(rb_funcall(cutout,id_sym,0));
   
    #ifdef DEBUG
      printf("id %d\n",p->id);
      fflush(stdout);
   #endif 
   s2=rb_ivar_get(rb_predicate,type_sym);
	if(s2==ID2SYM(rb_intern("single_fact"))){
		p->is_single_fact=1;
	}
	else{
		p->is_single_fact=0;
	}
   #ifdef DEBUG
      printf("filled!\n");
      fflush(stdout);
   #endif



}




Evidence *rb_predicates_to_evidence(VALUE rb_pred_1, VALUE rb_pred_2){
   int i;
	Evidence *e=(Evidence *) malloc(sizeof(Evidence));
   PredicateCutout *p1=(PredicateCutout *) malloc(sizeof(PredicateCutout));
   PredicateCutout *p2=(PredicateCutout *) malloc(sizeof(PredicateCutout));
	PredicateCutout*temp;
   #ifdef DEBUG
      printf("in rb_predicates_to_evidence\n");
      fflush(stdout);
   #endif

    
   e->match_result=NULL;
   hard_ruby_predicate_2_predicate_cutout(rb_pred_1, p1);
   hard_ruby_predicate_2_predicate_cutout(rb_pred_2, p2);
   
   #ifdef DEBUG
      printf("order predicates BEFORE %d %d\n",p1->id, p2->id);
      fflush(stdout);
   #endif

   
   if(p1->id < p2->id){
		e->pred_1=p1;
		e->pred_2=p2;
	}
	else{
		e->pred_1=p2;
		e->pred_2=p1;
	}
	e->obj1_string=strdup(RSTRING_PTR(rb_funcall(rb_ivar_get(rb_pred_1,object_sym),to_s_sym,0)));
	e->obj2_string=strdup(RSTRING_PTR(rb_funcall(rb_ivar_get(rb_pred_2,object_sym),to_s_sym,0)));
	e->obj1_string=trim(e->obj1_string);
	e->obj2_string=trim(e->obj2_string);
	
   for( i = 0; e->obj1_string[i]; i++){
      e->obj1_string[i]=tolower(e->obj1_string[i]);
   }

   for( i = 0; e->obj2_string[i]; i++){
      e->obj2_string[i]=tolower(e->obj2_string[i]);
   }
   #ifdef DEBUG
      printf("AFTER %d %d\n", p1->id, p2->id);
      printf("classes %s %s\n",rb_class2name(CLASS_OF(rb_pred_1)), rb_class2name(CLASS_OF(rb_pred_2))); 
      printf("checking null objects\n");
      fflush(stdout);
   #endif



   if(TYPE(rb_ivar_get(rb_pred_1,object_sym))==T_NIL || TYPE(rb_ivar_get(rb_pred_2,object_sym))==T_NIL){
      #ifdef DEBUG
      printf("has NULL, setting MATCH_NONE\n");
      fflush(stdout);
   #endif
   
      e->match_type=MATCH_NONE;
      return e;
   }
   
   #ifdef DEBUG
      printf("getting match type\n");
      fflush(stdout);
   #endif

	e->is_single_fact=(p1->relationship_db_id==p2->relationship_db_id);
   e->match_type=get_match_type(e);
  


   return e;
}	


static void update_evidence(int id, int match){
   char *sql;
   sqlite3_stmt *statement;
   int rc;
   if(match){
      sql="UPDATE evidence SET same=same+1 WHERE id=?";
   }
   else{
      sql="UPDATE evidence SET different=different+1 WHERE id=?";
   }
   sqlite3_prepare_v2(db, sql, strlen(sql), &statement, NULL);
   sqlite3_bind_int(statement,1,id);
   rc=sqlite3_step(statement);
   if(rc==SQLITE_ERROR){
      rb_raise (rb_eRuntimeError, sqlite3_errmsg(db));
   }
   sqlite3_finalize(statement); 
   
}


static VALUE method_steal_db_handle(VALUE self, VALUE handle){
	sqlite3_close(RDATA(handle)->data);
	RDATA(handle)->data=db;
	return Qnil;
}

static VALUE method_save_match(VALUE self, VALUE person_1, VALUE person_2, VALUE match_v){
   VALUE person_1_predicates;
   VALUE person_2_predicates;
   VALUE *person_1_ary;
   VALUE *person_2_ary;

   Evidence *e;
   
   int person_1_len, person_2_len,i,j,match=RTEST(match_v);
   person_1_predicates=rb_funcall(person_1,predicates_sym,0);
   person_2_predicates=rb_funcall(person_2,predicates_sym,0);
   person_1_len=RARRAY_LEN(person_1_predicates);
   person_2_len=RARRAY_LEN(person_2_predicates);
   person_1_ary=RARRAY_PTR(person_1_predicates);
   person_2_ary=RARRAY_PTR(person_2_predicates);
   update_evidence(-978,match);
   for(i=0;i<person_1_len;i++){
      for(j=0;j<person_2_len;j++){
	 e=rb_predicates_to_evidence(person_1_ary[i],person_2_ary[j]);
	 if(!(e->match_type==MATCH_NONE && !e->is_single_fact)){
		find_or_create_or_update_evidence(e,1,match);
		update_evidence(-979,match);
	 }
	 free_evidence(e);	 
      }
   }
	return Qnil;
}



static VALUE method_calculate_match(VALUE self, VALUE person_1, VALUE person_2){
   VALUE person_1_predicates;
   VALUE person_2_predicates;
   VALUE *person_1_ary;
   VALUE *person_2_ary;
   Evidence ***evidence;
   Evidence *e;
   int i,j,c,iterations;
   int high_1;
   int high_2;
   int adjusted_posterior=1;
   double retval;
   MatchResult total_matches;  
   int person_1_len, person_2_len;  
   mpq_t prior,result,highest,influence,posterior, one_minus_prior, temp;
   char *str_match_1;
	char *str_match_2;
   char *t1;
	char *t2;
	int c1,c2,clique_1,clique_2;
	int wipe;
	#ifdef DEBUG
      printf("beginning match\n");
      fflush(stdout);
   #endif

   
   if(db==NULL){
      rb_raise (rb_eRuntimeError, "database has not been set");
   }
   
   mpq_init(prior);
   mpq_init(result);
   mpq_init(highest);
	mpq_init(influence);
	mpq_init(posterior);
	mpq_init(one_minus_prior);
	mpq_init(temp);	
    #ifdef DEBUG
      printf("getting total match\n");
      fflush(stdout);
   #endif
 
   
   
   get_total_matches(&total_matches);
   mpq_set_ui(prior,total_matches.same,total_matches.same+total_matches.different);
   
   #ifdef DEBUG
      printf("getting_predicates\n");
      fflush(stdout);
   #endif

 
   
   person_1_predicates=rb_funcall(person_1,predicates_sym,0);
   person_2_predicates=rb_funcall(person_2,predicates_sym,0);
   person_1_len=RARRAY_LEN(person_1_predicates);
   person_2_len=RARRAY_LEN(person_2_predicates);
   person_1_ary=RARRAY_PTR(person_1_predicates);
   person_2_ary=RARRAY_PTR(person_2_predicates);
   evidence=(Evidence ***) malloc(person_1_len * sizeof(Evidence**));
   
   #ifdef DEBUG
      printf("pred classes %s %s", rb_class2name(CLASS_OF(person_1_predicates)), rb_class2name(CLASS_OF(person_2_predicates)));
      printf("creating evidence\n");
      fflush(stdout);
   #endif

   
   for(i=0;i<person_1_len;i++){
      evidence[i]=(Evidence **) malloc(person_2_len * sizeof(Evidence*));
      for(j=0;j<person_2_len;j++){
	 #ifdef DEBUG
	    printf("creating evidence %d %d\n",i,j);
	    fflush(stdout);
	 #endif

	      
	 e=rb_predicates_to_evidence(person_1_ary[i],person_2_ary[j]);
	 if(e->match_type==MATCH_NONE && !e->is_single_fact){
		evidence[i][j]=NULL;
		free_evidence(e);
		continue;
	 } 
	#ifdef DEBUG
	    printf("created evidence! %d %d\n",i,j);
	    fflush(stdout);
	 #endif


	 
	 evidence[i][j]=e;
		set_likelyhood_ratio(e);
      }
   }
   iterations=person_1_len<person_2_len ? person_1_len : person_2_len;
   
   #ifdef DEBUG
      printf("calculating match, iterations %d\n",iterations);
      fflush(stdout);
   #endif


   
   for(c=0;c<iterations;c++){
      #ifdef DEBUG
	    printf("iterator %d\n",c);
	     mpq_out_str (stdout, 10, prior);
	    fflush(stdout);
      #endif
      high_1=-1;
      high_2=-2;
	   
      mpq_set_ui(highest,0,1);
      /* find the most influential piece of evidence */
      
      for(i=0;i<person_1_len;i++){
			for(j=0;j<person_2_len;j++){
	     
				if(evidence[i][j]==NULL){
					#ifdef DEBUG
					printf("evidence %d %d null, continuing\n",i,j);
					fflush(stdout);
					#endif

					continue;
				
				}
				mpq_set(influence,evidence[i][j]->likelyhood_ratio);
				if(mpq_cmp(influence,MPQ_ONE)<0){
					if(mpq_sgn(influence)==0){
						mpq_set_ui(influence,1,1000000);
					}
					mpq_div(influence,MPQ_ONE,influence);
				}
				if(mpq_cmp(influence,highest)>0){
					mpq_set(highest,influence);
					high_1=i;
					high_2=j;
					#ifdef DEBUG
           				 printf("new highest\n",c);
             				mpq_out_str (stdout, 10, evidence[i][j]->likelyhood_ratio);
            				printf("pred_1 %d, pred_2 %d mtch %d",evidence[i][j]->pred_1->id, evidence[i][j]->pred_2->id, evidence[i][j]->match_type);
					fflush(stdout);
      					#endif
				}	    
			}
      }
     

      #ifdef DEBUG
	    printf("removing predicates %d %d",high_1,high_2);
	    fflush(stdout);
      #endif

      if(high_1<0 && high_2<0){
	 /* nothing to see here */
	 break;
      }
		/* update posterior */
		
      #ifdef DEBUG
	    printf("likelyhood\n");
	     mpq_out_str (stdout, 10, evidence[high_1][high_2]->likelyhood_ratio);
	    fflush(stdout);
      #endif
		mpq_mul(posterior, evidence[high_1][high_2]->likelyhood_ratio, prior);
		mpq_sub(one_minus_prior,MPQ_ONE, prior);
		mpq_add(temp, posterior, one_minus_prior);	
	   mpq_div(posterior,posterior,temp);
      mpq_set(prior,posterior);
		/* remove those predicates involved in the evidence from consideration */
	  
	 str_match_1=strdup(evidence[high_1][high_2]->obj1_string);
	 str_match_2=strdup(evidence[high_1][high_2]->obj2_string);
	 clique_1=evidence[high_1][high_2]->pred_1->clique;
	 clique_2=evidence[high_1][high_2]->pred_2->clique;
    for(i=0;i<person_1_len;i++){
		for(j=0;j<person_2_len;j++){
			if(evidence[i][j]==NULL) {continue; }
			t1=evidence[i][j]->obj1_string;
			t2=evidence[i][j]->obj2_string;
			c1=evidence[i][j]->pred_1->clique;
			c2=evidence[i][j]->pred_2->clique;
			if(i==high_1 ||
				j==high_2 ||
				strcmp(t1,str_match_1)==0 ||
				strcmp(t2,str_match_1)==0 ||
				strcmp(t1,str_match_2)==0 ||
				strcmp(t2,str_match_2)==0 ||
				(c1!=0 && (c1==clique_1 || c1==clique_2)) ||
				(c2!=0 && (c2==clique_1 || c2==clique_2))
			) {
				mpq_clear(evidence[i][j]->likelyhood_ratio);	
				free_evidence(evidence[i][j]);
				evidence[i][j]=NULL;
			}
		 }
	 }
	 free(str_match_1);
	 free(str_match_2);
			
   }

   /* clean up and return */

   retval=mpq_get_d(prior);
   mpq_clear(result);
   mpq_clear(highest);
   mpq_clear(prior);
	mpq_clear(posterior);
	mpq_clear(influence);
	mpq_clear(temp);
	mpq_clear(one_minus_prior);
	for(i=0;i<person_1_len;i++){
		for(j=0;j<person_2_len;j++){
			if(evidence[i][j]!=NULL){
				free_evidence(evidence[i][j]);
			}			
		}
		free(evidence[i]);
	}
   free(evidence);
   return rb_float_new(retval);
	 
         
}


void Init_identity_bayes() {
   unsigned char *sql;
   unsigned const char *temp;
   int rc,len;
   sqlite3_stmt *statement;
   VALUE rb_mIdentityBayes = rb_define_module("IdentityBayes");
 
   db=NULL;
   subject_sym=rb_intern("subject_type_id");
   object_id_sym=rb_intern("object_type_id");
   object_sym=rb_intern("@object");
   creator_sym=rb_intern("created_by_id");
   type_sym=rb_intern("@type");
   name_sym=rb_intern("@name");
   relationship_sym=rb_intern("relationship_id");
   klass_sym=rb_intern("class");
   to_s_sym=rb_intern("to_s");
   clique_sym=rb_intern("clique");
	id_sym=rb_intern("id");
   bayes_predicate_sym=rb_intern("@bayes_predicate");
   predicates_sym=rb_intern("_predicates");
   to_cutout_sym=rb_intern("to_cutout");
   rb_define_module_function(rb_mIdentityBayes, "calculate_match", method_calculate_match, 2);
   rb_define_module_function(rb_mIdentityBayes, "set_database", method_set_database, 1);
   rb_define_module_function(rb_mIdentityBayes, "save_match", method_save_match, 3);   
   rb_define_module_function(rb_mIdentityBayes, "steal_db_handle", method_steal_db_handle, 1);
	/* 1 as rational number using GnuMP library */
   
   mpq_init(MPQ_ONE);
   mpq_set_ui(MPQ_ONE,1,1);
   
   
   


}




