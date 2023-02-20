/*
File: version.go
Author: YJ
Email: yj1516268@outlook.com
Created Time: 2023-02-17 16:08:20

Description: 程序子命令'version'时执行
*/

package cmd

import (
	"fmt"
	"rolling/function"

	"github.com/spf13/cobra"
)

// versionCmd represents the version command
var versionCmd = &cobra.Command{
	Use:   "version",
	Short: "打印程序版本",
	Long:  `显示版本信息并退出`,
	Run: func(cmd *cobra.Command, args []string) {
		name := function.ProgramName()
		version := function.ProgramVersion()
		fmt.Printf("\033[1m%s\033[0m %s \033[1m%s\033[0m\n", name, "version", version)
	},
}

func init() {
	versionCmd.Flags().BoolP("help", "h", false, "Help for version")

	rootCmd.AddCommand(versionCmd)
}
