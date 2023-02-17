/*
Copyright © 2023 NAME HERE <EMAIL ADDRESS>
*/
package cmd

import (
	"os"

	"github.com/spf13/cobra"
)

// 在没有任何子命令的情况下调用时的基本命令
var rootCmd = &cobra.Command{
	Use:   "rolling",
	Short: "用于统计系统安装和更新信息",
	Long: `Rolling是一个适用于Arch Linux系的CLI工具
该程序用于统计系统安装和更新信息，输出系统安装时间、更新次数、更新频率等信息`,
	// Uncomment the following line if your bare application
	// has an action associated with it:
	// Run: func(cmd *cobra.Command, args []string) { },
}

// 由main.main调用
func Execute() {
	err := rootCmd.Execute()
	if err != nil {
		os.Exit(1)
	}
}

func init() {
	// 定义全局Flag
	rootCmd.Flags().BoolP("help", "h", false, "Help for Rolling")

	// rootCmd.PersistentFlags().StringVar(&cfgFile, "config", "", "config file (default is $HOME/.main.yaml)")
}
