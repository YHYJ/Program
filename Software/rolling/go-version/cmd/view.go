/*
Copyright © 2023 NAME HERE <EMAIL ADDRESS>
*/
package cmd

import (
	"rolling/function"

	"github.com/spf13/cobra"
)

// viewCmd represents the view command
var viewCmd = &cobra.Command{
	Use:   "view",
	Short: "查看系统信息",
	Long:  `查看收集到的系统安装和更新信息`,
	Run: func(cmd *cobra.Command, args []string) {
		function.SystemInfo()
	},
}

func init() {
	viewCmd.Flags().BoolP("help", "h", false, "Help for view")

	rootCmd.AddCommand(viewCmd)
}
