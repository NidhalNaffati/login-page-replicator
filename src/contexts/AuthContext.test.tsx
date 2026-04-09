import { describe, it, expect } from "vitest";
import { render, screen, fireEvent } from "@testing-library/react";
import { AuthProvider, useAuth } from "@/contexts/AuthContext";

/** Helper component that exposes auth state for testing. */
function AuthTestHarness() {
  const { user, login, logout } = useAuth();

  return (
    <div>
      <span data-testid="user">{user ? user.name : "none"}</span>
      <button onClick={() => login("TNEEIN01", "4YOU")}>login-valid</button>
      <button onClick={() => login("TNEEIN01", "wrong")}>login-invalid</button>
      <button onClick={() => login("unknown", "4YOU")}>login-unknown</button>
      <button onClick={logout}>logout</button>
    </div>
  );
}

function renderWithAuth() {
  return render(
    <AuthProvider>
      <AuthTestHarness />
    </AuthProvider>,
  );
}

describe("AuthContext", () => {
  it("starts with no authenticated user", () => {
    renderWithAuth();
    expect(screen.getByTestId("user").textContent).toBe("none");
  });

  it("logs in successfully with valid credentials", () => {
    renderWithAuth();
    fireEvent.click(screen.getByText("login-valid"));
    expect(screen.getByTestId("user").textContent).toBe("TNEEIN01 TEST1");
  });

  it("rejects login with wrong password", () => {
    renderWithAuth();
    fireEvent.click(screen.getByText("login-invalid"));
    expect(screen.getByTestId("user").textContent).toBe("none");
  });

  it("rejects login with unknown user", () => {
    renderWithAuth();
    fireEvent.click(screen.getByText("login-unknown"));
    expect(screen.getByTestId("user").textContent).toBe("none");
  });

  it("logs out after successful login", () => {
    renderWithAuth();
    fireEvent.click(screen.getByText("login-valid"));
    expect(screen.getByTestId("user").textContent).toBe("TNEEIN01 TEST1");

    fireEvent.click(screen.getByText("logout"));
    expect(screen.getByTestId("user").textContent).toBe("none");
  });

  it("performs case-insensitive lookup for identifiers", () => {
    const { container } = render(
      <AuthProvider>
        <TestCaseInsensitive />
      </AuthProvider>,
    );
    fireEvent.click(screen.getByText("login-lower"));
    expect(screen.getByTestId("user").textContent).toBe("TNEEIN01 TEST1");
  });
});

/** Tests that lowercase input maps to the uppercase key. */
function TestCaseInsensitive() {
  const { user, login } = useAuth();
  return (
    <div>
      <span data-testid="user">{user ? user.name : "none"}</span>
      <button onClick={() => login("tneein01", "4YOU")}>login-lower</button>
    </div>
  );
}

