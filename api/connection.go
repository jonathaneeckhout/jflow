package api

import (
	"database/sql"
	"fmt"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	_ "github.com/mattn/go-sqlite3"
)

type Claims struct {
	Username string `json:"username"`
	jwt.RegisteredClaims
}

var (
	db     *sql.DB
	jwtKey []byte
)

func Start(addr string, dbPath string, key string) error {
	var err error

	jwtKey = []byte(key)

	db, err = sql.Open("sqlite3", dbPath)
	if err != nil {
		return fmt.Errorf("failed to open db: %w", err)
	}
	defer db.Close()

	if err := createTable(); err != nil {
		return fmt.Errorf("failed to create tables: %w", err)
	}

	r := gin.Default()
	r.POST("/register", registerHandler)
	r.POST("/login", loginHandler)

	protected := r.Group("/api")
	protected.Use(authMiddleware())
	{
		protected.GET("/welcome", welcomeHandler)
	}

	fmt.Printf("🚀 Server running on http://%s\n", addr)
	return r.Run(addr)
}

func createTable() error {
	query := `
	CREATE TABLE IF NOT EXISTS users (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		username TEXT UNIQUE NOT NULL,
		password TEXT NOT NULL
	);`
	_, err := db.Exec(query)
	return err
}

func authMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Missing Authorization header"})
			c.Abort()
			return
		}

		var tokenString string
		fmt.Sscanf(authHeader, "Bearer %s", &tokenString)

		claims := &Claims{}
		token, err := jwt.ParseWithClaims(tokenString, claims, func(token *jwt.Token) (interface{}, error) {
			return jwtKey, nil
		})

		if err != nil || !token.Valid {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid token"})
			c.Abort()
			return
		}

		c.Set("username", claims.Username)

		c.Next()
	}
}

func welcomeHandler(c *gin.Context) {
	username, _ := c.Get("username")
	c.JSON(http.StatusOK, gin.H{"message": fmt.Sprintf("Welcome, %s!", username)})
}
