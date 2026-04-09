import { describe, it, expect, vi } from "vitest";
import { render, screen, fireEvent } from "@testing-library/react";
import TodoItem, { type Todo } from "@/components/TodoItem";

const baseTodo: Todo = { id: 1, text: "Buy groceries", completed: false };

describe("TodoItem", () => {
  it("renders the todo text", () => {
    render(<TodoItem todo={baseTodo} onToggle={vi.fn()} onDelete={vi.fn()} />);
    expect(screen.getByText("Buy groceries")).toBeInTheDocument();
  });

  it("applies line-through style when completed", () => {
    const completed: Todo = { ...baseTodo, completed: true };
    render(<TodoItem todo={completed} onToggle={vi.fn()} onDelete={vi.fn()} />);
    const span = screen.getByText("Buy groceries");
    expect(span.className).toContain("line-through");
  });

  it("does not apply line-through style when not completed", () => {
    render(<TodoItem todo={baseTodo} onToggle={vi.fn()} onDelete={vi.fn()} />);
    const span = screen.getByText("Buy groceries");
    expect(span.className).not.toContain("line-through");
  });

  it("calls onToggle with the todo id when toggle button is clicked", () => {
    const onToggle = vi.fn();
    render(<TodoItem todo={baseTodo} onToggle={onToggle} onDelete={vi.fn()} />);
    // The toggle button is the first button in the component
    const buttons = screen.getAllByRole("button");
    fireEvent.click(buttons[0]);
    expect(onToggle).toHaveBeenCalledWith(1);
  });

  it("calls onDelete with the todo id when delete button is clicked", () => {
    const onDelete = vi.fn();
    render(<TodoItem todo={baseTodo} onToggle={vi.fn()} onDelete={onDelete} />);
    // The delete button is the second button
    const buttons = screen.getAllByRole("button");
    fireEvent.click(buttons[1]);
    expect(onDelete).toHaveBeenCalledWith(1);
  });
});

