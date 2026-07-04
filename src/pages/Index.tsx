import { LoginCard } from "@/components/LoginCard";

const Index = () => {
  return (
    <div className="relative flex min-h-screen items-center justify-center overflow-hidden bg-[hsl(var(--background))]">
      {/* Background gradient overlay */}
      <div
        className="absolute inset-0"
        style={{
          background:
            "linear-gradient(180deg, hsl(220 20% 8%) 0%, hsl(260 40% 12%) 40%, hsl(280 50% 18%) 70%, hsl(330 60% 30% / 0.6) 100%)",
        }}
      />
      {/* Purple/pink light bloom at bottom */}
      <div
        className="absolute bottom-0 left-1/2 -translate-x-1/2 w-[120%] h-[45%]"
        style={{
          background:
            "radial-gradient(ellipse at 60% 100%, hsl(290 70% 40% / 0.5) 0%, hsl(330 70% 45% / 0.3) 40%, transparent 70%)",
        }}
      />
      <LoginCard />
    </div>
  );
};

export default Index;
