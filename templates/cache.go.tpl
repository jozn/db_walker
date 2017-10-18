package {{ .PackageName}}

import (
    "strconv"
    "ms/sun/base"
)

{{range .Tables}}
	{{if .PrimaryKey}}
		{{- $short := .ShortName}}
		{{- $table := .TableNameOut}}
		{{- $typ := .TableNameGo }}
		{{- $_ := "" }}
		{{- $id := (.PrimaryKey.ColumnName) }}

		{{if (eq .PrimaryKey.GoTypeOut "int") }}
		{{/* //{{ .TableNameGo }} Events - * (Manually copy this to other location) */}}
		func (c _StoreImpl) Get{{ .TableNameGo }}By{{$id}}{{$_}} ({{$id}} int) (*{{ .TableNameGo }},bool){
			o ,ok :=RowCache.Get("{{ .TableNameGo }}:"+strconv.Itoa({{$id}}))
			if ok {
				if obj, ok := o.(*{{ .TableNameGo }});ok{
					return obj, true
				}
			}
			obj2 ,err := {{ .TableNameGo }}By{{.PrimaryKey.ColumnName}}(base.DB, {{$id}})
			if err == nil {
				return obj2, true
			}
			XOLogErr(err)
			return nil, false
		}

		func (c _StoreImpl) PreLoad{{ .TableNameGo }}By{{$id}}s{{$_}} (ids []int) {
			not_cached := make([]int,0,len(ids))

			for _,id := range ids {
				_ ,ok :=RowCache.Get("{{ .TableNameGo }}:"+strconv.Itoa(id))
				if !ok {
					not_cached = append(not_cached,id)
				}
			}

			if len(not_cached) > 0 {
				New{{ .TableNameGo }}_Selector().{{$id}}_In(not_cached).GetRows(base.DB)
			}
		}
		{{else if ( eq .PrimaryKey.GoTypeOut "string" ) }}
		func (c _StoreImpl) Get{{ .TableNameGo }}By{{$id}}{{$_}} ({{$id}} string) (*{{ .TableNameGo }},bool){
			o ,ok :=RowCache.Get("{{ .TableNameGo }}:"+{{$id}})
			if ok {
				if obj, ok := o.(*{{ .TableNameGo }});ok{
					return obj, true
				}
			}
			obj2 ,err := {{ .TableNameGo }}By{{.PrimaryKey.ColumnName}}(base.DB, {{$id}})
			if err == nil {
				return obj2, true
			}
			XOLogErr(err)
			return nil, false
		}

		func (c _StoreImpl) PreLoad{{ .TableNameGo }}By{{$id}}s{{$_}} (ids []string) {
			not_cached := make([]string,0,len(ids))

			for _,id := range ids {
				_ ,ok :=RowCache.Get("{{ .TableNameGo }}:"+id)
				if !ok {
					not_cached = append(not_cached,id)
				}
			}

			if len(not_cached) > 0 {
				New{{ .TableNameGo }}_Selector().{{$id}}_In(not_cached).GetRows(base.DB)
			}
		}
		{{end}}
		// yes 222 {{.PrimaryKey.GoTypeOut }}
	{{end}}
{{end}}