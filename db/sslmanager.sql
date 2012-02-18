--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

SET search_path = public, pg_catalog;

--
-- Name: ssl_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE ssl_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.ssl_seq OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: ssl; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE ssl (
    id integer DEFAULT nextval('ssl_seq'::regclass) NOT NULL,
    ssl_domain_name character varying,
    ssl_country_code character varying(2),
    ssl_state character varying,
    ssl_locality character varying,
    ssl_organization_name character varying,
    ssl_organizational_unit character varying,
    ssl_email character varying,
    ssl_key character varying,
    ssl_csr character varying,
    ssl_crt character varying
);


ALTER TABLE public.ssl OWNER TO postgres;

--
-- Name: ssl_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY ssl
    ADD CONSTRAINT ssl_pkey PRIMARY KEY (id);


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

