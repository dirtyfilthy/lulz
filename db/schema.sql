CREATE TABLE object_types (
	id INTEGER PRIMARY KEY,
	name TEXT UNIQUE
);

CREATE TABLE relationships (
	id INTEGER PRIMARY KEY,
	name TEXT UNIQUE
);

CREATE TABLE predicate_cutouts (
	id INTEGER PRIMARY KEY,
	object_type_id INTEGER,
	subject_type_id INTEGER,
	relationship_id INTEGER,
	created_by_id INTEGER
);

CREATE INDEX object_type_index ON predicate_cutouts (object_type_id);
CREATE INDEX created_by_index ON predicate_cutouts (created_by_id);
CREATE INDEX subject_type_index ON predicate_cutouts (subject_type_id);
CREATE INDEX relationship_index ON predicate_cutouts (relationship_id);

CREATE TABLE evidence (
	id INTEGER PRIMARY KEY,
	pred_1 INTEGER,
	pred_2 INTEGER,
	same INTEGER,
	different INTEGER,
	match_type INTEGER
);

CREATE INDEX evidence_pred_1 ON evidence (pred_1);
CREATE INDEX evidence_pred_2 ON evidence (pred_2);
CREATE INDEX evidence_match_type ON evidence (match_type);

INSERT INTO evidence (id,same,different) VALUES (-978,1,100);
INSERT INTO evidence (id,same,different) VALUES (-979,100,100);
INSERT INTO evidence (id,same,different) VALUES (0,0,0);

CREATE TABLE markov_agent_times (
	id INTEGER PRIMARY KEY,
	markov_produced_object_id INTEGER,
	ran INTEGER DEFAULT 0,
	total_time FLOAT DEFAULT 0.0

);
CREATE TABLE markov_decision_policies (
        id INTEGER PRIMARY KEY,
        agent_id INTEGER,
        match_reward FLOAT,
        total_time FLOAT
);
CREATE TABLE markov_predicate_chains (
	id INTEGER PRIMARY KEY,
	pred_1_id INTEGER,
	pred_2_id INTEGER,
	relevance INTEGER,
	new_policy BOOLEAN
);



CREATE TABLE markov_produced_objects (
	id INTEGER PRIMARY KEY,
	agent_id INTEGER,
	objects INTEGER DEFAULT 0,
	matches INTEGER DEFAULT 0,
	count INTEGER DEFAULT 0,
	markov_predicate_chain_id INTEGER,
	profiles INTEGER
	
);
CREATE TABLE markov_produced_predicates (
	id INTEGER PRIMARY KEY,
	predicate_id INTEGER,
	count INTEGER DEFAULT 0,
	total INTEGER DEFAULT 0,
	rel_0_count INTEGER DEFAULT 0,
	rel_1_count INTEGER DEFAULT 0,
	rel_2_count INTEGER DEFAULT 0,
	rel_3_count INTEGER DEFAULT 0,
	rel_4_count INTEGER DEFAULT 0,
	markov_produced_object_id INTEGER
);

CREATE TABLE markov_agent_run_profiles (
	 id INTEGER PRIMARY KEY,
	 markov_predicate_chain_id INTEGER,
	 agent_id INTEGER,
	 ran INTEGER DEFAULT 0,
	 tried INTEGER DEFAULT 0
);

CREATE TABLE markov_chain_scores (
	id INTEGER PRIMARY KEY,
	markov_predicate_chain_id INTEGER,
	count INTEGER,
	agent_id INTEGER,
	score INTEGER
);

CREATE index markov_chain_score_index ON markov_chain_scores(markov_predicate_chain_id,agent_id);
CREATE INDEX run_profiles_chain_id ON markov_agent_run_profiles (markov_predicate_chain_id );
CREATE INDEX run_profiles_agent_id ON  markov_agent_run_profiles (agent_id);
CREATE UNIQUE INDEX run_profiles_both ON  markov_agent_run_profiles (markov_predicate_chain_id,agent_id);
CREATE INDEX markov_all ON markov_predicate_chains(pred_1_id,pred_2_id,relevance);
CREATE INDEX markov_produced_object_chain_id ON markov_produced_objects (markov_predicate_chain_id);
CREATE INDEX markov_produced_predicates_object_id ON markov_produced_predicates (markov_produced_object_id); 
CREATE INDEX evidence_both ON evidence(pred_1,pred_2);
CREATE INDEX quicker_index ON predicate_cutouts (object_type_id, relationship_id, subject_type_id);











