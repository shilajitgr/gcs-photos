package middleware

import (
	"context"
	"net/http"
	"strings"

	firebase "firebase.google.com/go/v4/auth"
	"github.com/nicholasgasior/cgs-photos/server/pkg/response"
)

type contextKey string

const userIDKey contextKey = "userID"

// Auth returns middleware that verifies Firebase Auth tokens.
func Auth(authClient *firebase.Client) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			authHeader := r.Header.Get("Authorization")
			if authHeader == "" {
				response.Error(w, http.StatusUnauthorized, "missing authorization header")
				return
			}

			token := strings.TrimPrefix(authHeader, "Bearer ")
			if token == authHeader {
				response.Error(w, http.StatusUnauthorized, "invalid authorization format")
				return
			}

			decoded, err := authClient.VerifyIDToken(r.Context(), token)
			if err != nil {
				response.Error(w, http.StatusUnauthorized, "invalid or expired token")
				return
			}

			ctx := context.WithValue(r.Context(), userIDKey, decoded.UID)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

// UserIDFromContext extracts the authenticated user ID from the request context.
func UserIDFromContext(ctx context.Context) string {
	uid, _ := ctx.Value(userIDKey).(string)
	return uid
}
