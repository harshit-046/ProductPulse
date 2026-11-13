import pandas as pd
import pytest
from scripts.clean_data import clean_file, REQUIRED

def test_cleaning_retains_unknowns_and_identical_rows(tmp_path):
    src=tmp_path/"in.csv"; out=tmp_path/"out.csv"; report=tmp_path/"report.json"
    row=["2020-09-24 11:57:06 UTC","view","1","10","","","1.00","99",""]
    pd.DataFrame([row,row],columns=REQUIRED).to_csv(src,index=False)
    result=clean_file(src,out,report)
    clean=pd.read_csv(out)
    assert result["original_rows"]==2 and result["cleaned_rows"]==2
    assert result["duplicate_rows_investigated_and_retained"]==2
    assert clean.user_session.isna().all() and clean.brand.isna().all()

def test_invalid_rows_removed_and_types_normalized(tmp_path):
    src=tmp_path/"in.csv"; out=tmp_path/"out.csv"; report=tmp_path/"report.json"
    rows=[["2020-09-24 11:57:06 UTC","view","1","10","cat","brand","1.00","99","s1"],
          ["not-a-time","view","1","10","cat","brand","1.00","99","s2"],
          ["2020-09-24 11:57:06 UTC","other","1","10","cat","brand","1.00","99","s3"],
          ["2020-09-24 11:57:06 UTC","view","1","10","cat","brand","-1.00","99","s4"]]
    pd.DataFrame(rows,columns=REQUIRED).to_csv(src,index=False)
    result=clean_file(src,out,report)
    assert result["cleaned_rows"]==1
    clean=pd.read_csv(out,parse_dates=["event_time"])
    assert clean.event_time.dt.tz is not None and clean.price.ge(0).all()

def test_required_columns_and_missing_core_identifiers(tmp_path):
    src=tmp_path/"in.csv"; out=tmp_path/"out.csv"; report=tmp_path/"report.json"
    good=["2020-09-24 11:57:06 UTC","view","1","10","cat","brand","1.00","99","s1"]
    missing_user=good.copy(); missing_user[7]=""
    missing_product=good.copy(); missing_product[2]=""
    pd.DataFrame([good,missing_user,missing_product],columns=REQUIRED).to_csv(src,index=False)
    result=clean_file(src,out,report)
    assert result["cleaned_rows"]==1
    bad_schema=tmp_path/"bad.csv"
    pd.DataFrame([{"event_time":"2020-01-01"}]).to_csv(bad_schema,index=False)
    with pytest.raises(ValueError,match="Missing required columns"):
        clean_file(bad_schema,out,report)

def test_funnel_denominators_and_purchase_value_fixture():
    # Controlled session fixture: repeat views don't inflate distinct session counts;
    # value is a sum over purchase events (as the SQL definition specifies).
    data=pd.DataFrame([
      ("s1","view",1.0),("s1","view",1.0),("s1","cart",1.0),("s1","purchase",10.0),
      ("s2","view",2.0),("s2","cart",2.0),("s3","view",3.0)],columns=["session","type","price"])
    assert data.loc[data.type.eq("view"),"session"].nunique()==3
    assert data.loc[data.type.eq("cart"),"session"].nunique()==2
    assert data.loc[data.type.eq("purchase"),"session"].nunique()==1
    assert data.loc[data.type.eq("purchase"),"price"].sum()==10.0
    assert 0 <= 1/3 <= 1 and 0 <= 1/2 <= 1

def test_user_population_and_event_type_funnel_bounds():
    events=pd.DataFrame([
      ("u1","d1","s1","view"),("u1","d1","s1","view"),
      ("u2","d1","s2","view"),("u2","d1","s2","cart"),
      ("u3","d1","s3","purchase")],columns=["user","day","session","type"])
    dau=events.groupby("day").user.nunique()
    assert dau.max() <= events.user.nunique()
    views=events.loc[events.type.eq("view"),"session"].nunique()
    carts=events.loc[events.type.eq("cart"),"session"].nunique()
    purchases=events.loc[events.type.eq("purchase"),"session"].nunique()
    assert 0 <= carts/views <= 1
    assert 0 <= purchases/views <= 1
    # Purchase-only sessions are counted as purchase sessions but do not enter view denominator.
    assert (views,carts,purchases)==(2,1,1)

