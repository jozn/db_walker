package x
// GENERATED BY XO. DO NOT EDIT.
import (
	"database/sql"
	"database/sql/driver"
	"encoding/csv"
	"errors"
	"fmt"
	"regexp"
	"strings"
	//"time"
	 "ms/sun/helper"
    "strconv"
    "github.com/jmoiron/sqlx"
)

{{- $short := .ShortName}}// (shortname .TableNameGo "err" "res" "sqlstr" "db" "XOLog") -}}
{{- $table := .TableSchemeOut }}//(schema .Schema .Table.TableName) -}}
{{- $typ := .TableNameGo}}// .TableNameGo}}
{{- if .Comment -}}
// {{ .Comment }}
{{- else -}}
// {{ .TableNameGo }} represents a row from '{{ $table }}'.
{{- end }}

// Manualy copy this to project
type {{ .TableNameGo }}__ struct {
{{- range .Columns }}
	{{ .ColumnName }} {{ .GoTypeOut }} `json:"{{ .ColumnName }}"` // {{ .ColumnName }} -
{{- end }}
{{- if .PrimaryKey }}
	// xo fields
	_exists, _deleted bool
{{ end -}}
}


{{ if .PrimaryKey }}
// Exists determines if the {{ .TableNameGo}} exists in the database.
func ({{ $short }} *{{ .TableNameGo }}) Exists() bool {
	return {{ $short }}._exists
}

// Deleted provides information if the {{ .TableNameGo }} has been deleted from the database.
func ({{ $short }} *{{ .TableNameGo }}) Deleted() bool {
	return {{ $short }}._deleted
}

// Insert inserts the {{ .TableNameGo }} to the database.
func ({{ $short }} *{{ .TableNameGo }}) Insert(db XODB) error {
	var err error

	// if already exist, bail
	if {{ $short }}._exists {
		return errors.New("insert failed: already exists")
	}

{{ if not .IsAutoIncrement  }}
	// sql insert query, primary key must be provided
	const sqlstr = `INSERT INTO {{ $table }} (` +
		`{{ colnames .Columns }}` +
		`) VALUES (` +
		`{{ colvals .Columns }}` +
		`)`

	// run query
	if LogTableSqlReq.{{.TableNameGo}} {
		XOLog(sqlstr, {{ fieldnames .Columns $short }})
	}
	_, err = db.Exec(sqlstr, {{ fieldnames .Columns $short }})
	if err != nil {
		return err
	}

	// set existence
	{{ $short }}._exists = true
{{ else }}
	// sql insert query, primary key provided by autoincrement
	const sqlstr = `INSERT INTO {{ $table }} (` +
		`{{ colnames .Columns .PrimaryKey.ColumnName }}` +
		`) VALUES (` +
		`{{ colvals .Columns .PrimaryKey.ColumnName }}` +
		`)`

	// run query
	if LogTableSqlReq.{{.TableNameGo}} {
		XOLog(sqlstr, {{ fieldnames .Columns $short .PrimaryKey.ColumnName }})
	}
	res, err := db.Exec(sqlstr, {{ fieldnames .Columns $short .PrimaryKey.ColumnName }})
	if err != nil {
		if LogTableSqlReq.{{.TableNameGo}} {
			XOLogErr(err)
		}
		return err
	}

	// retrieve id
	id, err := res.LastInsertId()
	if err != nil {
		if LogTableSqlReq.{{.TableNameGo}} {
			XOLogErr(err)
		}
		return err
	}

	// set primary key and existence
	{{ $short }}.{{ .PrimaryKey.ColumnName }} = {{ .PrimaryKey.GoTypeOut }}(id)
	{{ $short }}._exists = true
{{ end }}

	On{{ .TableNameGo }}_AfterInsert({{ $short }})

	return nil
}

// Insert inserts the {{ .TableNameGo }} to the database.
func ({{ $short }} *{{ .TableNameGo }}) Replace(db XODB) error {
	var err error

	// sql query
{{ if not .IsAutoIncrement  }}
	const sqlstr = `REPLACE INTO {{ $table }} (` +
		`{{ colnames .Columns }}` +
		`) VALUES (` +
		`{{ colvals .Columns }}` +
		`)`

	// run query
	if LogTableSqlReq.{{.TableNameGo}} {
		XOLog(sqlstr, {{ fieldnames .Columns $short  }})
	}
	_, err = db.Exec(sqlstr, {{ fieldnames .Columns $short }})
	if err != nil {
		if LogTableSqlReq.{{.TableNameGo}} {
			XOLogErr(err)
		}
		return err
	}

	{{ $short }}._exists = true
{{else}}
	const sqlstr = `REPLACE INTO {{ $table }} (` +
		`{{ colnames .Columns .PrimaryKey.ColumnName }}` +
		`) VALUES (` +
		`{{ colvals .Columns .PrimaryKey.ColumnName }}` +
		`)`

	// run query
	if LogTableSqlReq.{{.TableNameGo}} {
		XOLog(sqlstr, {{ fieldnames .Columns $short .PrimaryKey.ColumnName }})
	}
	res, err := db.Exec(sqlstr, {{ fieldnames .Columns $short .PrimaryKey.ColumnName }})
	if err != nil {
		if LogTableSqlReq.{{.TableNameGo}} {
			XOLogErr(err)
		}
		return err
	}

	// retrieve id
	id, err := res.LastInsertId()
	if err != nil {
		if LogTableSqlReq.{{.TableNameGo}} {
			XOLogErr(err)
		}
		return err
	}

	// set primary key and existence
	{{ $short }}.{{ .PrimaryKey.ColumnName }} = {{ .PrimaryKey.GoTypeOut }}(id)
	{{ $short }}._exists = true
{{end}}

	On{{ .TableNameGo }}_AfterInsert({{ $short }})

	return nil
}

// Update updates the {{ .TableNameGo }} in the database.
func ({{ $short }} *{{ .TableNameGo }}) Update(db XODB) error {
	var err error

	// if doesn't exist, bail
	if !{{ $short }}._exists {
		return errors.New("update failed: does not exist")
	}

	// if deleted, bail
	if {{ $short }}._deleted {
		return errors.New("update failed: marked for deletion")
	}

	// sql query
	const sqlstr = `UPDATE {{ $table }} SET ` +
		`{{ colnamesquery .Columns ", " .PrimaryKey.ColumnName }}` +
		` WHERE {{ colname .PrimaryKey }} = ?`

	// run query
	if LogTableSqlReq.{{.TableNameGo}} {
		XOLog(sqlstr, {{ fieldnames .Columns $short .PrimaryKey.ColumnName }}, {{ $short }}.{{ .PrimaryKey.ColumnName }})
	}
	_, err = db.Exec(sqlstr, {{ fieldnames .Columns $short .PrimaryKey.ColumnName }}, {{ $short }}.{{ .PrimaryKey.ColumnName }})

	if LogTableSqlReq.{{.TableNameGo}} {
		XOLogErr(err)
	}
	On{{ .TableNameGo }}_AfterUpdate({{ $short }})

	return err
}

// Save saves the {{ .TableNameGo }} to the database.
func ({{ $short }} *{{ .TableNameGo }}) Save(db XODB) error {
	if {{ $short }}.Exists() {
		return {{ $short }}.Update(db)
	}

	return {{ $short }}.Replace(db)
}

// Delete deletes the {{ .TableNameGo }} from the database.
func ({{ $short }} *{{ .TableNameGo }}) Delete(db XODB) error {
	var err error

	// if doesn't exist, bail
	if !{{ $short }}._exists {
		return nil
	}

	// if deleted, bail
	if {{ $short }}._deleted {
		return nil
	}

	// sql query
	const sqlstr = `DELETE FROM {{ $table }} WHERE {{ colname .PrimaryKey }} = ?`

	// run query
	if LogTableSqlReq.{{.TableNameGo}} {
		XOLog(sqlstr, {{ $short }}.{{ .PrimaryKey.ColumnName }})
	}
	_, err = db.Exec(sqlstr, {{ $short }}.{{ .PrimaryKey.ColumnName }})
	if err != nil {
		if LogTableSqlReq.{{.TableNameGo}} {
			XOLogErr(err)
		}
		return err
	}

	// set deleted
	{{ $short }}._deleted = true

	On{{ .TableNameGo }}_AfterDelete({{ $short }})

	return nil
}

////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////// Querify gen - ME /////////////////////////////////////////
//.TableNameGo= table name
{{- $deleterType := printf "__%s_Deleter" .TableNameGo}}
{{- $updaterType := printf "__%s_Updater" .TableNameGo}}
{{- $selectorType := printf "__%s_Selector" .TableNameGo}}
{{- $updater := printf "__%s_Updater" .TableNameGo}}
{{ $ms_gen_types := ms_gen_types }} // _Deleter, _Updater

// orma types
type {{ $deleterType }} struct {
	wheres   []whereClause
    whereSep string
}

type {{ $updaterType }} struct {
	wheres   []whereClause
	updates   map[string]interface{}
    whereSep string
}

type {{ $selectorType }} struct {
    wheres   []whereClause
    selectCol string
    whereSep  string
    orderBy string//" order by id desc //for ints
    limit int
    offset int
}

func New{{ .TableNameGo}}_Deleter()  *{{ $deleterType }} {
	    d := {{ $deleterType }} {whereSep: " AND "}
	    return &d
}

func New{{ .TableNameGo}}_Updater()  *{{ $updaterType }} {
	    u := {{ $updaterType }} {whereSep: " AND "}
	    u.updates =  make(map[string]interface{},10)
	    return &u
}

func New{{ .TableNameGo}}_Selector()  *{{ $selectorType }} {
	    u := {{ $selectorType }} {whereSep: " AND ",selectCol: "*"}
	    return &u
}


{{- $ms_cond_list := ms_conds }}
{{- $ms_str_cond := ms_str_cond }}
{{- $ms_in := ms_in }}
{{- $Columns := .Columns }}
/////////////////////////////// Where for all /////////////////////////////
//// for ints all selector updater, deleter
{{ range (ms_to_slice $deleterType $updaterType $selectorType) }}
		{{ $operationType := . }}
			////////ints
func (u *{{$operationType}}) Or () *{{$operationType}} {
    u.whereSep = " OR "
    return u
}
		{{- range $Columns }}

			{{- $colName := .ColumnName }}
			{{- $colType := .GoTypeOut }}

				{{- if (or (eq $colType "int64") (eq $colType "int") ) }}

func (u *{{$operationType}}) {{ $colName }}_In (ins []int) *{{$operationType}} {
    w := whereClause{}
    var insWhere []interface{}
    for _, i:= range ins {
        insWhere = append(insWhere,i)
    }
    w.args = insWhere
    w.condition = " {{ $colName }} IN("+helper.DbQuestionForSqlIn(len(ins))+") "
    u.wheres = append(u.wheres, w)

    return u
}

func (u *{{$operationType}}) {{ $colName }}_Ins (ins ...int) *{{$operationType}} {
    w := whereClause{}
    var insWhere []interface{}
    for _, i:= range ins {
        insWhere = append(insWhere,i)
    }
    w.args = insWhere
    w.condition = " {{ $colName }} IN("+helper.DbQuestionForSqlIn(len(ins))+") "
    u.wheres = append(u.wheres, w)

    return u
}

func (u *{{$operationType}}) {{ $colName }}_NotIn (ins []int) *{{$operationType}} {
    w := whereClause{}
    var insWhere []interface{}
    for _, i:= range ins {
        insWhere = append(insWhere,i)
    }
    w.args = insWhere
    w.condition = " {{ $colName }} NOT IN("+helper.DbQuestionForSqlIn(len(ins))+") "
    u.wheres = append(u.wheres, w)

    return u
}

					{{- with $ms_cond_list }}
						{{- range  .  }}

func (d *{{$operationType}}) {{ $colName }}{{ .Suffix }} (val int) *{{$operationType}} {
    w := whereClause{}
    var insWhere []interface{}
    insWhere = append(insWhere,val)
    w.args = insWhere
    w.condition = " {{ $colName }} {{.Condition}} ? "
    d.wheres = append(d.wheres, w)

    return d
}
						{{- end }}
					{{- end }}

				{{- end }}

		{{- end }}

{{ end }}


///// for strings //copy of above with type int -> string + rm if eq + $ms_str_cond
{{ range (ms_to_slice $deleterType $updaterType $selectorType) }}
		{{ $operationType := . }}
			////////ints
		{{- range $Columns }}

			{{- $colName := .ColumnName }}
			{{- $colType := .GoTypeOut }}

				{{- if (eq $colType "string") }}

func (u *{{$operationType}}) {{ $colName }}_In (ins []string) *{{$operationType}} {
    w := whereClause{}
    var insWhere []interface{}
    for _, i:= range ins {
        insWhere = append(insWhere,i)
    }
    w.args = insWhere
    w.condition = " {{ $colName }} IN("+helper.DbQuestionForSqlIn(len(ins))+") "
    u.wheres = append(u.wheres, w)

    return u
}

func (u *{{$operationType}}) {{ $colName }}_NotIn (ins []string) *{{$operationType}} {
    w := whereClause{}
    var insWhere []interface{}
    for _, i:= range ins {
        insWhere = append(insWhere,i)
    }
    w.args = insWhere
    w.condition = " {{ $colName }} NOT IN("+helper.DbQuestionForSqlIn(len(ins))+") "
    u.wheres = append(u.wheres, w)

    return u
}

//must be used like: UserName_like("hamid%")
func (u *{{$operationType}}) {{ $colName }}_Like (val string) *{{$operationType}} {
    w := whereClause{}
    var insWhere []interface{}
    insWhere = append(insWhere,val)
    w.args = insWhere
    w.condition = " {{ $colName }} LIKE ? "
    u.wheres = append(u.wheres, w)

    return u
}

					{{- with $ms_str_cond }}
						{{- range  .  }}

func (d *{{$operationType}}) {{ $colName }}{{ .Suffix }} (val string) *{{$operationType}} {
    w := whereClause{}
    var insWhere []interface{}
    insWhere = append(insWhere,val)
    w.args = insWhere
    w.condition = " {{ $colName }} {{.Condition}} ? "
    d.wheres = append(d.wheres, w)

    return d
}
						{{- end }}
					{{- end }}

				{{- end }}

		{{- end }}

{{ end }}
/// End of wheres for selectors , updators, deletor





/////////////////////////////// Updater /////////////////////////////

{{ $operationType := $updaterType }}

{{- range $Columns }}

	{{- $colName := .ColumnName }}
	{{- $colType := .GoTypeOut }}

	//ints
	{{- if (or (eq $colType "int64") (eq $colType "int") ) }}

func (u *{{$updaterType}}){{ $colName }} (newVal int) *{{$updaterType}} {
    u.updates[" {{$colName}} = ? "] = newVal
    return u
}

func (u *{{$updaterType}}){{ $colName }}_Increment (count int) *{{$updaterType}} {
	if count > 0 {
		u.updates[" {{$colName}} = {{$colName}}+? "] = count
	}

	if count < 0 {
		u.updates[" {{$colName}} = {{$colName}}-? "] = -(count) //make it positive
	}

    return u
}
	{{- end }}

	//string
	{{- if (eq $colType "string") }}
func (u *{{$updaterType}}){{ $colName }} (newVal string) *{{$updaterType}} {
    u.updates[" {{$colName}} = ? "] = newVal
    return u
}
	{{- end }}

{{- end }}


/////////////////////////////////////////////////////////////////////
/////////////////////// Selector ///////////////////////////////////
{{ $operationType := $selectorType }}

//Select_* can just be used with: .GetString() , .GetStringSlice(), .GetInt() ..GetIntSlice()
{{- range $Columns }}

	{{- $colName := .ColumnName }}
	{{- $colType := .GoTypeOut }}

func (u *{{$selectorType}}) OrderBy_{{ $colName }}_Desc () *{{$selectorType}} {
    u.orderBy = " ORDER BY {{$colName}} DESC "
    return u
}

func (u *{{$selectorType}}) OrderBy_{{ $colName }}_Asc () *{{$selectorType}} {
    u.orderBy = " ORDER BY {{$colName}} ASC "
    return u
}

func (u *{{$selectorType}}) Select_{{ $colName }} () *{{$selectorType}} {
    u.selectCol = "{{$colName}}"
    return u
}
{{- end }}

func (u *{{$selectorType}}) Limit(num int) *{{$selectorType}} {
    u.limit = num
    return u
}

func (u *{{$selectorType}}) Offset(num int) *{{$selectorType}} {
    u.offset = num
    return u
}


func (u *{{$selectorType}}) Order_Rand () *{{$selectorType}} {
    u.orderBy = " ORDER BY RAND() "
    return u
}


/////////////////////////  Queryer Selector  //////////////////////////////////
func (u *{{$selectorType}})_stoSql ()  (string,[]interface{}) {
	sqlWherrs, whereArgs := whereClusesToSql(u.wheres,u.whereSep)

	sqlstr := "SELECT " +u.selectCol +" FROM {{ $table }}"

	if len( strings.Trim(sqlWherrs," ") ) > 0 {//2 for safty
		sqlstr += " WHERE "+ sqlWherrs
	}

	if u.orderBy != ""{
        sqlstr += u.orderBy
    }

    if u.limit != 0 {
        sqlstr += " LIMIT " + strconv.Itoa(u.limit)
    }

    if u.offset != 0 {
        sqlstr += " OFFSET " + strconv.Itoa(u.offset)
    }
    return sqlstr,whereArgs
}

func (u *{{$selectorType}}) GetRow (db *sqlx.DB) (*{{ $typ }},error) {
	var err error

	sqlstr, whereArgs := u._stoSql()

	if LogTableSqlReq.{{.TableNameGo}} {
		XOLog(sqlstr,whereArgs )
	}

	row := &{{$typ}}{}
	//by Sqlx
	err = db.Get(row ,sqlstr, whereArgs...)
	if err != nil {
		if LogTableSqlReq.{{.TableNameGo}} {
			XOLogErr(err)
		}
		return nil, err
	}

	row._exists = true

	On{{ .TableNameGo}}_LoadOne(row)

	return row, nil
}

func (u *{{$selectorType}}) GetRows (db *sqlx.DB) ([]*{{ $typ }},error) {
	var err error

	sqlstr, whereArgs := u._stoSql()

	if LogTableSqlReq.{{.TableNameGo}} {
		XOLog(sqlstr,whereArgs )
	}

	var rows []*{{$typ}}
	//by Sqlx
	err = db.Unsafe().Select(&rows ,sqlstr, whereArgs...)
	if err != nil {
		if LogTableSqlReq.{{.TableNameGo}} {
			XOLogErr(err)
		}
		return nil, err
	}

	/*for i:=0;i< len(rows);i++ {
		rows[i]._exists = true
	}*/

	for i:=0;i< len(rows);i++ {
		rows[i]._exists = true
	}

	On{{ .TableNameGo}}_LoadMany(rows)

	return rows, nil
}

//dep use GetRows()
func (u *{{$selectorType}}) GetRows2 (db *sqlx.DB) ([]{{ $typ }},error) {
	var err error

	sqlstr, whereArgs := u._stoSql()

	if LogTableSqlReq.{{.TableNameGo}} {
		XOLog(sqlstr,whereArgs )
	}
	var rows []*{{$typ}}
	//by Sqlx
	err = db.Unsafe().Select(&rows ,sqlstr, whereArgs...)
	if err != nil {
		if LogTableSqlReq.{{.TableNameGo}} {
			XOLogErr(err)
		}
		return nil, err
	}

	/*for i:=0;i< len(rows);i++ {
		rows[i]._exists = true
	}*/

	for i:=0;i< len(rows);i++ {
		rows[i]._exists = true
	}

	On{{ .TableNameGo}}_LoadMany(rows)

	rows2 := make([]{{$typ}}, len(rows))
	for i:=0;i< len(rows);i++ {
		cp := *rows[i]
		rows2[i]= cp
	}

	return rows2, nil
}



func (u *{{$selectorType}}) GetString (db *sqlx.DB) (string,error) {
	var err error

	sqlstr, whereArgs := u._stoSql()

	if LogTableSqlReq.{{.TableNameGo}} {
		XOLog(sqlstr,whereArgs )
	}

	var res string
	//by Sqlx
	err = db.Get(&res ,sqlstr, whereArgs...)
	if err != nil {
		if LogTableSqlReq.{{.TableNameGo}} {
			XOLogErr(err)
		}
		return "", err
	}

	return res, nil
}

func (u *{{$selectorType}}) GetStringSlice (db *sqlx.DB) ([]string,error) {
	var err error

	sqlstr, whereArgs := u._stoSql()

	if LogTableSqlReq.{{.TableNameGo}} {
		XOLog(sqlstr,whereArgs )
	}
	var rows []string
	//by Sqlx
	err = db.Select(&rows ,sqlstr, whereArgs...)
	if err != nil {
		if LogTableSqlReq.{{.TableNameGo}} {
			XOLogErr(err)
		}
		return nil, err
	}

	return rows, nil
}

func (u *{{$selectorType}}) GetIntSlice (db *sqlx.DB) ([]int,error) {
	var err error

	sqlstr, whereArgs := u._stoSql()

	if LogTableSqlReq.{{.TableNameGo}} {
		XOLog(sqlstr,whereArgs )
	}
	var rows []int
	//by Sqlx
	err = db.Select(&rows ,sqlstr, whereArgs...)
	if err != nil {
		if LogTableSqlReq.{{.TableNameGo}} {
			XOLogErr(err)
		}
		return nil, err
	}

	return rows, nil
}

func (u *{{$selectorType}}) GetInt (db *sqlx.DB) (int,error) {
	var err error

	sqlstr, whereArgs := u._stoSql()

	if LogTableSqlReq.{{.TableNameGo}} {
		XOLog(sqlstr,whereArgs )
	}
	var res int
	//by Sqlx
	err = db.Get(&res ,sqlstr, whereArgs...)
	if err != nil {
		if LogTableSqlReq.{{.TableNameGo}} {
			XOLogErr(err)
		}
		return 0, err
	}

	return res, nil
}

/////////////////////////  Queryer Update Delete //////////////////////////////////
func (u *{{$updaterType}})Update (db XODB) (int,error) {
    var err error

    var updateArgs []interface{}
    var sqlUpdateArr  []string
    for up, newVal := range u.updates {
        sqlUpdateArr = append(sqlUpdateArr, up)
        updateArgs = append(updateArgs, newVal)
    }
    sqlUpdate:= strings.Join(sqlUpdateArr, ",")

    sqlWherrs, whereArgs := whereClusesToSql(u.wheres,u.whereSep)

    var allArgs []interface{}
    allArgs = append(allArgs, updateArgs...)
    allArgs = append(allArgs, whereArgs...)

    sqlstr := `UPDATE {{ $table }} SET ` + sqlUpdate

    if len( strings.Trim(sqlWherrs," ") ) > 0 {//2 for safty
		sqlstr += " WHERE " +sqlWherrs
	}

	if LogTableSqlReq.{{.TableNameGo}} {
    	XOLog(sqlstr,allArgs)
    }
    res, err := db.Exec(sqlstr, allArgs...)
    if err != nil {
    	if LogTableSqlReq.{{.TableNameGo}} {
    		XOLogErr(err)
    	}
        return 0,err
    }

    num, err := res.RowsAffected()
    if err != nil {
    	if LogTableSqlReq.{{.TableNameGo}} {
    		XOLogErr(err)
    	}
        return 0,err
    }

    return int(num),nil
}

func (d *{{$deleterType}})Delete (db XODB) (int,error) {
    var err error
    var wheresArr []string
    for _,w := range d.wheres{
        wheresArr = append(wheresArr,w.condition)
    }
    wheresStr := strings.Join(wheresArr, d.whereSep)

    var args []interface{}
    for _,w := range d.wheres{
        args = append(args,w.args...)
    }

    sqlstr := "DELETE FROM {{ $table}} WHERE " + wheresStr

    // run query
    if LogTableSqlReq.{{.TableNameGo}} {
    	XOLog(sqlstr, args)
    }
    res, err := db.Exec(sqlstr, args...)
    if err != nil {
    	if LogTableSqlReq.{{.TableNameGo}} {
    		XOLogErr(err)
    	}
        return 0,err
    }

    // retrieve id
    num, err := res.RowsAffected()
    if err != nil {
    	if LogTableSqlReq.{{.TableNameGo}} {
    		XOLogErr(err)
    	}
        return 0,err
    }

    return int(num),nil
}

///////////////////////// Mass insert - replace for  {{ .TableNameGo}} ////////////////
{{ if not .IsAutoIncrement  }}
func MassInsert_{{ .TableNameGo}}(rows []{{ .TableNameGo}} ,db XODB) error {
	if len(rows) == 0 {
		return errors.New("rows slice should not be empty - inserted nothing")
	}
	var err error
	ln := len(rows)
	//s:= "({{ ms_question_mark .Columns }})," //`(?, ?, ?, ?),`
	s:= "({{ ms_question_mark .Columns }})," //`(?, ?, ?, ?),`
	insVals_:= strings.Repeat(s, ln)
	insVals := insVals_[0:len(insVals_)-1]
	// sql query
	sqlstr := "INSERT INTO {{ $table }} (" +
		"{{ colnames .Columns  }}" +
		") VALUES " + insVals

	// run query
	vals := make([]interface{},0, ln * 5)//5 fields

	for _,row := range rows {
		// vals = append(vals,row.UserId)
		{{ ms_append_fieldnames .Columns "vals" }}
	}

	if LogTableSqlReq.{{.TableNameGo}} {
		XOLog(sqlstr, " MassInsert len = ", ln, vals)
	}
	_, err = db.Exec(sqlstr, vals...)
	if err != nil {
		if LogTableSqlReq.{{.TableNameGo}} {
			XOLogErr(err)
		}
		return err
	}

	return nil
}

func MassReplace_{{ .TableNameGo}}(rows []{{ .TableNameGo}} ,db XODB) error {
	if len(rows) == 0 {
		return errors.New("rows slice should not be empty - inserted nothing")
	}
	var err error
	ln := len(rows)
	//s:= "({{ ms_question_mark .Columns }})," //`(?, ?, ?, ?),`
	s:= "({{ ms_question_mark .Columns }})," //`(?, ?, ?, ?),`
	insVals_:= strings.Repeat(s, ln)
	insVals := insVals_[0:len(insVals_)-1]
	// sql query
	sqlstr := "REPLACE INTO {{ $table }} (" +
		"{{ colnames .Columns  }}" +
		") VALUES " + insVals

	// run query
	vals := make([]interface{},0, ln * 5)//5 fields

	for _,row := range rows {
		// vals = append(vals,row.UserId)
		{{ ms_append_fieldnames .Columns "vals" }}
	}

	if LogTableSqlReq.{{.TableNameGo}} {
		XOLog(sqlstr, " MassReplace len = ", ln, vals)
	}
	_, err = db.Exec(sqlstr, vals...)
	if err != nil {
		if LogTableSqlReq.{{.TableNameGo}} {
			XOLogErr(err)
		}
		return err
	}

	return nil

}
{{ else }}

func MassInsert_{{ .TableNameGo}}(rows []{{ .TableNameGo}} ,db XODB) error {
	if len(rows) == 0 {
		return errors.New("rows slice should not be empty - inserted nothing")
	}
	var err error
	ln := len(rows)
	//s:= "( ms_question_mark .Columns .PrimaryKey.ColumnName }})," //`(?, ?, ?, ?),`
	s:= "({{ ms_question_mark .Columns .PrimaryKey.ColumnName }})," //`(?, ?, ?, ?),`
	insVals_:= strings.Repeat(s, ln)
	insVals := insVals_[0:len(insVals_)-1]
	// sql query
	sqlstr := "INSERT INTO {{ $table }} (" +
		"{{ colnames .Columns .PrimaryKey.ColumnName }}" +
		") VALUES " + insVals

	// run query
	vals := make([]interface{},0, ln * 5)//5 fields

	for _,row := range rows {
		// vals = append(vals,row.UserId)
		{{ ms_append_fieldnames .Columns "vals" .PrimaryKey.ColumnName }}
	}

	if LogTableSqlReq.{{.TableNameGo}} {
		XOLog(sqlstr, " MassInsert len = ", ln, vals)
	}
	_, err = db.Exec(sqlstr, vals...)
	if err != nil {
		if LogTableSqlReq.{{.TableNameGo}} {
			XOLogErr(err)
		}
		return err
	}

	return nil
}

func MassReplace_{{ .TableNameGo}}(rows []{{ .TableNameGo}} ,db XODB) error {
	var err error
	ln := len(rows)
	s:= "({{ ms_question_mark .Columns .PrimaryKey.ColumnName }})," //`(?, ?, ?, ?),`
	insVals_:= strings.Repeat(s, ln)
	insVals := insVals_[0:len(insVals_)-1]
	// sql query
	sqlstr := "REPLACE INTO {{ $table }} (" +
		"{{ colnames .Columns .PrimaryKey.ColumnName }}" +
		") VALUES " + insVals

	// run query
	vals := make([]interface{},0, ln * 5)//5 fields

	for _,row := range rows {
		// vals = append(vals,row.UserId)
		{{ ms_append_fieldnames .Columns "vals" .PrimaryKey.ColumnName }}
	}

	if LogTableSqlReq.{{.TableNameGo}} {
		XOLog(sqlstr, " MassReplace len = ", ln , vals)
	}
	_, err = db.Exec(sqlstr, vals...)
	if err != nil {
		if LogTableSqlReq.{{.TableNameGo}} {
			XOLogErr(err)
		}
		return err
	}

	return nil
}

{{ end }}


//////////////////// Play ///////////////////////////////
{{- range $Columns }}

			{{- $colName := .ColumnName }}
			{{- $colType := .GoTypeOut }}

			// {{- /* $colType }} {{ $colName */}}

{{- end}}





{{- end }}

