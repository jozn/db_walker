package src

import (
	"fmt"
	"log"

	"github.com/kr/pretty"
	"github.com/hokaccha/go-prettyjson"
)

func NoErr(err error) {
	if err != nil {
		log.Panic(err)
	}
}

func PertyPrint(a interface{}) {
	fmt.Printf("%# v \n", pretty.Formatter(a))
}

func PertyPrint2(a interface{}) {
	fmt.Printf("%# v \n", ToJsonPerety(a))
}
func ToJsonPerety(structoo interface{}) string {
	bts, _ := prettyjson.Marshal(structoo)
	return string(bts)
}